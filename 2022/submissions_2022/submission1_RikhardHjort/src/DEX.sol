// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

contract DEX {
    address public owner;
    bool    public paused;

    IERC20  public  token1;
    IERC20  public  token2;
    uint256 private k;

    uint256 public totalShares;
    mapping (address => uint256) public shares;

    constructor(IERC20 _token1, IERC20 _token2, address _owner) {
        token1 = _token1;
        token2 = _token2;
        owner = _owner;
    }

    function init(uint256 amount1, uint256 amount2) external {
        require(token1.balanceOf(address(this)) == 0 && token2.balanceOf(address(this)) == 0);
        require(token1.transferFrom(msg.sender, address(this), amount1));
        require(token2.transferFrom(msg.sender, address(this), amount2));
        totalShares = shares[msg.sender] = amount1;
        _sync();
    }
    
    modifier notPaused() {
        require(!paused);
        _;
    }

    function pause() external {
        require(msg.sender == owner);
        paused = true;
    }

    function unpause() external {
        require(msg.sender == owner);
        paused = false;
        _sync();
    }

    function swap(IERC20 tokenIn, uint256 amountIn, IERC20 tokenOut, uint256 amountOut) external notPaused() {
        require((tokenIn == token1 && tokenOut == token2) || (tokenIn == token2 && tokenOut == token1));
        require(tokenIn.transferFrom(msg.sender, address(this), amountIn));
        require(tokenOut.transfer(msg.sender, amountOut));
        uint256 x = tokenIn .balanceOf(address(this));
        uint256 y = tokenOut.balanceOf(address(this));
        require(1000 * x * y - amountIn * y * 5 >= 1000 * k, "bad swap"); // charge fee, (x - 0.005 * amountIn) * y >= k
        _sync();
    }

    function addLiquidity(uint256 sharesToMint) external notPaused() {
        // amount / balanceOf == sharesToMint / totalShares
        uint256 amount1 = token1.balanceOf(address(this)) * sharesToMint / totalShares;
        uint256 amount2 = token2.balanceOf(address(this)) * sharesToMint / totalShares;
        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;
        require(token1.transferFrom(msg.sender, address(this), amount1));
        require(token2.transferFrom(msg.sender, address(this), amount2));
        _sync();
    }

    function removeLiquidity(uint256 sharesToBurn) external {
        uint256 amount1 = token1.balanceOf(address(this)) * sharesToBurn / totalShares;
        uint256 amount2 = token2.balanceOf(address(this)) * sharesToBurn / totalShares;
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;
        require(token1.transfer(msg.sender, amount1));
        require(token2.transfer(msg.sender, amount2));
        _sync();
    }

    function flashLoan(IERC3156FlashBorrower receiver, IERC20 token, uint256 amount, bytes calldata data) external notPaused() returns (bool) {
        require(token == token1 || token == token2);
        uint256 fee = amount * 5 / 1000; // 0.5 %
        require(token.transfer(address(receiver), amount));
        require(receiver.onFlashLoan(msg.sender, address(token), amount, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan"));
        require(IERC20(token).transferFrom(address(receiver), address(this), amount + fee));
        _sync();
        return true;
    }
    
    function _sync() internal {
        k = token1.balanceOf(address(this)) * token2.balanceOf(address(this));
    }
}

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

interface IERC3156FlashBorrower {
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32);
}