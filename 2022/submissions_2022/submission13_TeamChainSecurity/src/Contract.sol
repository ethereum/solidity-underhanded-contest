// SPDX-License-Identifier: GPL-3.0-only 
pragma solidity 0.8.12;

import "solmate/tokens/ERC20.sol";

// Do not support tokens that return false on error
interface ReasonableERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract V2PairAndRouter is ERC20 {
    ReasonableERC20 public immutable token0;
    ReasonableERC20 public immutable token1;

    // uses single storage slot, wastes 24 bits to trigger poor auditors
    uint112 private reserve0;           
    uint112 private reserve1; 
    uint8 private unlocked = 1;

    error InsufficientInputAmout();
    error InsufficientLiquidity();
    error InsufficientLiquidityBurned();
    error InsufficientLiquidityMinted();
    error InsufficientOutputAmout();
    error K();
    error Overflow();
    error PairLocked();

    modifier lock() {
        if(unlocked != 1) revert PairLocked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _token0, address _token1) ERC20("Pair", "PAI", 18) {
        token0 = ReasonableERC20(_token0);
        token1 = ReasonableERC20(_token1);
    }

    // Original from Uniswap
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    } 

    function _update(uint balance0, uint balance1) private {
        if(!(balance0 <= type(uint112).max && balance1 <= type(uint112).max)) revert Overflow();
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(uint112(balance0), uint112(balance1));
    }


    // Allow unbalanced minting
    // - Computes the newly minted amount
    // - Compares to the 
    function mint(address to, uint amount0, uint amount1, uint minOut) external lock returns (uint liquidity) {
        if(amount0 > 0) token0.transferFrom(msg.sender, address(this), amount0);
        if(amount1 > 0) token1.transferFrom(msg.sender, address(this), amount1);
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        amount0 = balance0 - _reserve0;
        amount1 = balance1 - _reserve1;

        uint oldSupply = totalSupply; 
        if (oldSupply == 0) {
            liquidity = 10**18;
        } else {
            uint previousK = uint(_reserve0) * uint(_reserve1);
            uint newK = balance0 * balance1;
            liquidity = (sqrt(newK * 10**36 / previousK) - 10**18) * oldSupply / 10**18;
            // Take fee to prevent pesky JiT liquidity
            liquidity = liquidity * 997 / 1000;
            if(liquidity == 0) revert InsufficientLiquidityMinted(); 
        }
        require(liquidity >= minOut);
        _mint(to, liquidity);
        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // Allow burning of LP tokens without need for previous approve() 
    function burn(address to, uint liquidity) external lock returns (uint amount0, uint amount1) {
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        uint oldSupply = totalSupply; 
        // Compute respective token ratio
        amount0 = liquidity * balance0 / oldSupply;
        amount1 = liquidity * balance1 / oldSupply;
        if(amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        _burn(msg.sender, liquidity);
        token0.transfer(to, amount0);
        // Transfer out the tokens
        token1.transfer(to, amount1);
        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // Swap
    // - Can be used as a standalone contract for single-pair swaps
    // - Or in combination with a router for multi-pair swaps
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint amount0In, uint amount1In) external lock {
        if(amount0In > 0) token0.transferFrom(msg.sender, address(this), amount0In);
        if(amount1In > 0) token1.transferFrom(msg.sender, address(this), amount1In);
        if(amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmout();
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        if(amount0Out >= _reserve0 || amount1Out >= _reserve1) revert InsufficientLiquidity();

        uint balance0;
        uint balance1;
        require(to != address(token0) && to != address(token1));
        // Optimistically transfer tokens
        if (amount0Out > 0) token0.transfer(to, amount0Out); 
        if (amount1Out > 0) token1.transfer(to, amount1Out);
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));
        amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if(amount0In == 0 && amount1In == 0) revert InsufficientInputAmout(); 
        { 
        uint balance0Adjusted = balance0 * 1000 - (amount0In * 3);
        uint balance1Adjusted = balance1 * 1000 - (amount1In * 3);
        if(balance0Adjusted * balance1Adjusted < uint(_reserve0) * (_reserve1) * 1000**2) revert K();
        }
        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}
