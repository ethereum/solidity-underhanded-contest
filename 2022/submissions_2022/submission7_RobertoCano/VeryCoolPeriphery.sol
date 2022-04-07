//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./VeryCoolPoolTokens.sol";
import "./VeryCoolPoolETH.sol";

/**
    Main contract of the protocol. Helps deposit and withdraw from the pools

    It allows for multi-deposit in one single transaction for gas saving
 */
contract VeryCoolPeryphery is Ownable {
    using Address for address;

    uint256 public constant SHORT_STAKING_TIME = 10 days;
    uint256 public constant LONG_STAKING_TIME = 40 days;

    mapping(address => bool) public isETHPool;
    mapping(address => bool) public isTokenPool;

    address public defaultETHStaker;
    address public defaultTokenStaker;
    VeryCoolPoolETH public defaultETHPool;

    constructor(address ethStaker, address tokenStaker) {
        defaultETHStaker = ethStaker;
        defaultTokenStaker = tokenStaker;

        defaultETHPool = new VeryCoolPoolETH();

        isETHPool[address(defaultETHPool)] = true;
    }

    function addETHPool(address pool) external onlyOwner {
        isETHPool[pool] = true;
    }

    function addTokenPool(address pool) external {
        // Ownership of the pool must be transferred to this contract
        isTokenPool[pool] = true;
    }

    /**
        Allows to deposit on several pools on one single transaction
     */
    function deposit(
        address[] calldata pools,
        bytes[] calldata params,
        uint256[] calldata sendValues
    ) external payable {
        require(pools.length == params.length, "Number of pools and parameters must match");
        require(pools.length == sendValues.length, "Number of pools and send values must match");

        for (uint256 i = 0; i < pools.length; ++i) {
            bytes memory depositCall = _getCallData(pools[i], params[i]);
            pools[i].functionCallWithValue(depositCall, sendValues[i], "ERROR depositing funds");
        }
    }

    function _getSelector(address pool) internal view returns (bytes4) {
        if (isETHPool[pool]) {
            return VeryCoolPoolETH.deposit.selector;
        } else if (isTokenPool[pool]) {
            return VeryCoolPoolTokens.deposit.selector;
        } else {
            revert("Unknown pool");
        }
    }

    function _getCallData(address pool, bytes calldata params) internal view returns (bytes memory) {
        bytes4 selector = _getSelector(pool);

        if (isTokenPool[pool]) {
            (uint128 amountA, uint128 amountB) = abi.decode(params, (uint128, uint128));
            return abi.encodeWithSelector(selector, _msgSender(), amountA, amountB, defaultTokenStaker);
        } else if (isETHPool[pool]) {
            bool longStake = abi.decode(params, (bool));

            uint256 endTimestamp = longStake
                ? (block.timestamp + LONG_STAKING_TIME)
                : (block.timestamp + SHORT_STAKING_TIME);

            return abi.encodeWithSelector(selector, _msgSender(), endTimestamp, defaultETHStaker);
        } else {
            revert("Unknown pool");
        }
    }

    function withdraw(address pool) external {
        if (isETHPool[pool]) {
            IVeryCoolPoolETH(pool).withdraw(payable(_msgSender()), defaultETHStaker);
        } else if (isTokenPool[pool]) {
            IVeryCoolPoolTokens(pool).withdraw(_msgSender(), defaultTokenStaker);
        } else {
            revert("Unknown pool");
        }
    }
}
