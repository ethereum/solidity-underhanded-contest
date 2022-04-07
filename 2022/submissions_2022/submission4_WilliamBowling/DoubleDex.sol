// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required functions for interacting with the tokens
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface LoanReceiver {
    function loan(uint256 tokenOneAmount, uint256 tokenTwoAmount) external;
}

/**
 * @dev A simple DEX where `tokenOne` is always twice as much as `tokenTwo`
 */
contract DoubleDex {
    event Deposit(address user, uint256 tokenOneAmount, uint256 tokenTwoAmount);
    event Withdraw(address user, uint256 tokenOneAmount, uint256 tokenTwoAmount);
    event Swap(address user, int256 tokenOneAmount, int256 tokenTwoAmount);

    mapping(address => uint256) tokenOneBalances;
    mapping(address => uint256) tokenTwoBalances;

    address public tokenOne;
    address public tokenTwo;

    bool private locked = false;

    modifier lock() {
        require(!locked);
        locked = true;

        _;

        locked = false;
    }

    constructor(address _tokenOne, address _tokenTwo) {
        require(_tokenOne != address(0));
        require(_tokenTwo != address(0));

        tokenOne = _tokenOne;
        tokenTwo = _tokenTwo;
    }

    /**
     * @dev Deposit tokens.
     *
     * Any ratio of tokens can be deposited, the ratio is only enforces when withdrawing
     */
    function depositTokens(uint256 tokenOneAmount, uint256 tokenTwoAmount) external {
        tokenOneBalances[msg.sender] += tokenOneAmount;
        tokenTwoBalances[msg.sender] += tokenTwoAmount;

        emit Deposit(msg.sender, tokenOneAmount, tokenTwoAmount);

        require(IERC20(tokenOne).transferFrom(msg.sender, address(this), tokenOneAmount), 'Transfer failed');
        require(IERC20(tokenTwo).transferFrom(msg.sender, address(this), tokenTwoAmount), 'Transfer failed');
    }

    /**
     * @dev Withdraw tokens.
     *
     * Requires that after the withdrawal the balance of `tokenTwo` is 2x the balance of `tokenOne`
     */
    function withdrawTokens(uint256 tokenOneAmount, uint256 tokenTwoAmount) external {
        require(IERC20(tokenOne).balanceOf(address(this)) >= tokenOneAmount, 'Not enough liquidity');
        require(IERC20(tokenTwo).balanceOf(address(this)) >= tokenTwoAmount, 'Not enough liquidity');

        require(tokenOneBalances[msg.sender] >= tokenOneAmount, 'Not enough balance');
        require(tokenTwoBalances[msg.sender] >= tokenTwoAmount, 'Not enough balance');

        require(willMaintainRatio(tokenOneAmount, tokenTwoAmount), 'Must maintain the 2-1 ratio of tokens');

        tokenOneBalances[msg.sender] -= tokenOneAmount;
        tokenTwoBalances[msg.sender] -= tokenTwoAmount;

        emit Withdraw(msg.sender, tokenOneAmount, tokenTwoAmount);

        require(IERC20(tokenOne).transfer(msg.sender, tokenOneAmount), 'Transfer failed');
        require(IERC20(tokenTwo).transfer(msg.sender, tokenTwoAmount), 'Transfer failed');
    }

    /**
     * @dev The fixed exchange rate between tokenOne and tokenTwo, which is always double.
     */
    function tokenRate(uint256 amount) public pure returns (uint256) {
        return amount << 1;
    }

    /**
     * @dev Check to see if the deposit or withdrawal will keep the correct ratio of token
     */
    function willMaintainRatio(uint256 tokenOneAmount, uint256 tokenTwoAmount) public view returns (bool) {
        uint256 tokenOneBalance = IERC20(tokenOne).balanceOf(address(this));
        uint256 tokenTwoBalance = IERC20(tokenTwo).balanceOf(address(this));

        return tokenRate(tokenOneBalance - tokenOneAmount) == tokenTwoBalance - tokenTwoAmount;
    }

    /**
     * @dev Swap `tokenOneAmount` of `tokenOne` for 2x the amount of `tokenTwo`
     */
    function swapTokenOneForTokenTwo(uint256 tokenOneAmount) external {
        require(tokenOneAmount > 0, 'Amount must be > 0');

        uint256 tokenTwoAmount = tokenRate(tokenOneAmount);

        require(tokenOneBalances[msg.sender] >= tokenOneAmount, 'Not enough balance');

        tokenOneBalances[msg.sender] -= tokenOneAmount;
        tokenTwoBalances[msg.sender] += tokenTwoAmount;

        emit Swap(msg.sender, -int256(tokenOneAmount), int256(tokenTwoAmount));
    }

    /**
     * @dev Swap 2x `tokenOneAmount` of `tokenTwo` for `tokenOneAmount` of `tokenTwo`
     */
    function swapTokenTwoForTokenOne(uint256 tokenOneAmount) external {
        require(tokenOneAmount > 0, 'Amount must be > 0');

        uint256 tokenTwoAmount = tokenRate(tokenOneAmount);

        require(tokenTwoBalances[msg.sender] >= tokenTwoAmount, 'Not enough balance');

        tokenTwoBalances[msg.sender] -= tokenTwoAmount;
        tokenOneBalances[msg.sender] += tokenOneAmount;

        emit Swap(msg.sender, int256(tokenOneAmount), -int256(tokenTwoAmount));
    }

    /**
     * @dev Allow anyone to take out a flash loan for a 0.3% fee
     */
    function flashLoan(
        uint256 tokenOneAmount,
        uint256 tokenTwoAmount,
        address to
    ) external lock {
        require(to != address(0));

        uint256 preTokenOneBalance = IERC20(tokenOne).balanceOf(address(this));
        uint256 preTokenTwoBalance = IERC20(tokenTwo).balanceOf(address(this));

        require(preTokenOneBalance >= tokenOneAmount, 'Not enough liquidity');
        require(preTokenTwoBalance >= tokenOneAmount, 'Not enough liquidity');

        uint256 tokenOneFee = (tokenOneAmount * 3) / 1000;
        uint256 tokenTwoFee = (tokenTwoAmount * 3) / 1000;

        require(IERC20(tokenOne).transfer(msg.sender, tokenOneAmount), 'Transfer failed');
        require(IERC20(tokenTwo).transfer(msg.sender, tokenTwoAmount), 'Transfer failed');

        LoanReceiver(to).loan(tokenOneAmount, tokenTwoAmount);

        require(IERC20(tokenOne).balanceOf(address(this)) >= preTokenOneBalance + tokenOneFee, 'Loan not repaid');
        require(IERC20(tokenTwo).balanceOf(address(this)) >= preTokenTwoBalance + tokenTwoFee, 'Loan not repaid');
    }
}
