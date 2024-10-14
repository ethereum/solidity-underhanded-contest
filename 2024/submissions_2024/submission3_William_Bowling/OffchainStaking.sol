// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface UserCallback {
    function userCreated() external returns (bool);
}

contract OffchainStaking {
    struct User {
        address owner;
        uint256 balance;
    }

    event UserCreated(address indexed owner);
    event Deposit(address indexed owner, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);
    event TransferUser(address indexed owner, address newOwner);
    event EmergencyWithdraw(address indexed to, uint256 amount);
    event ReentracyDetected(address indexed owner);

    address public multisig;
    IERC20 public token;

    mapping(address => User) public users;

    constructor(address _multisig, IERC20 _token) {
        multisig = _multisig;
        token = _token;
    }

    ////////////////////////////////////////////////////
    //////////////// External Functions ////////////////
    ////////////////////////////////////////////////////

    function createUser() external {
        createUserInternal();
    }

    function deposit(uint256 amount) external {
        User storage user = getUser();
        depositInternal(amount, user);
    }

    function withdraw(uint256 amount) external {
        User storage user = getUser();
        withdrawInternal(amount, user);
    }

    function transferUser(address newOwner) external {
        User storage user = getUser();
        user.owner = newOwner;
    }

    function emergencyWithdraw(address to, uint256 amount) external {
        require(msg.sender == multisig, "Not multisig");
        require(token.transfer(to, amount), "Transfer failed");

        emit EmergencyWithdraw(to, amount);
    }

    ///////////////////////////////////////////////////
    //////////////////// Modifiers ////////////////////
    ///////////////////////////////////////////////////

    modifier createReentrancy(address addr) {
        userCreateStart(addr);
        _;
        userCreateEnd(addr);
    }

    modifier skipIfReentrant(address addr, User storage user) {
        if (isInUserCreate(addr)) {
            emit ReentracyDetected(user.owner);
            return;
        }

        _;
    }

    ////////////////////////////////////////////////////
    //////////////// Internal Functions ////////////////
    ////////////////////////////////////////////////////

    function createUserInternal() internal createReentrancy(msg.sender) returns (User storage user) {
        user = users[msg.sender];
        user.owner = msg.sender;

        UserCallback callback = UserCallback(msg.sender);
        if (address(callback).code.length > 0) {
            require(callback.userCreated());
        }

        emit UserCreated(msg.sender);
    }

    function depositInternal(uint256 amount, User storage user) internal skipIfReentrant(msg.sender, user) {
        user.balance += amount;
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        emit Deposit(msg.sender, amount);
    }

    function withdrawInternal(uint256 amount, User storage user) internal skipIfReentrant(msg.sender, user) {
        require(user.balance >= amount, "Insufficient balance");
        user.balance -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function getUser() internal skipIfReentrant(msg.sender, user=user) returns (User storage user) {
        user = users[msg.sender];
    }

    ////////////////////////////////////////////////////
    ////////////// TStore/TLoad wrappers ///////////////
    ////////////////////////////////////////////////////

    function userCreateStart(address addr) internal {
        tstore(keccak256(abi.encodePacked("userCreate", addr)), 1);
    }

    function userCreateEnd(address addr) internal {
        tstore(keccak256(abi.encodePacked("userCreate", addr)), 0);
    }

    function isInUserCreate(address addr) internal view returns (bool) {
        return tload(keccak256(abi.encodePacked("userCreate", addr))) == 1;
    }

    function tstore(bytes32 key, uint256 value) internal {
        assembly {
            tstore(key, value)
        }
    }

    function tload(bytes32 key) internal view returns (uint256 value) {
        assembly {
            value := tload(key)
        }
    }
}
