// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./LightStorage.sol";

/// @notice Vesting contract configuration
/// @dev This configuration should prevent integer overflow possibility
///   in the `_calcTotalVested` and `create` functions
struct Config {
    address admin;
    uint256 maxAmount;
    uint256 maxDuration;
    uint256 maxCliffPercent;
    uint256 fee;
    IERC20 token;
}

/// @notice Vesting schedule parameters
/// @dev Here cliff is duration part, not a direct timestamp
struct Vesting {
    address user;
    uint256 amount;
    uint256 claimed;
    uint256 start;
    uint256 duration;
    uint256 cliff;
}

/// @title LightStorageIntegration Contract
/// @notice Abstract contract that integrates `LightStorage` operations with Config and Vesting data structures
/// @dev The contract contains rug pull ability
abstract contract LightStorageIntegration {
    using LightStorage for bytes32;

    bytes32 public constant CONFIG_KEY = bytes32(uint256(keccak256("combinedKey.vesting.config")) - 1);
    bytes32 public constant VESTING_KEY = bytes32(uint256(keccak256("combinedKey.vesting.vestingPrefix")) - 1);

    /// @notice Check the status of combined storage at the key
    /// @return The status of the combined storage (Empty, HashOnly, or Loaded)
    function keyStatus(bytes32 key) public view returns (KeyStatus) {
        return key.status();
    }

    /// @notice Preload the Config struct data into combined storage
    function loadConfig(bytes32 key, Config memory config) public {
        key.load(abi.encode(config));
    }

    /// @notice Preload the Vesting struct data into combined storage
    function loadVesting(bytes32 key, Vesting memory vesting) public {
        key.load(abi.encode(vesting));
    }

    /// @notice Retrieve the Config struct from combined storage at the key
    /// @return The Config struct
    function getConfig(bytes32 key) public view returns (Config memory) {
        return abi.decode(key.read(), (Config));
    }

    /// @notice Retrieve the Vesting struct from combined storage at the key
    /// @return The Vesting struct
    function getVesting(bytes32 key) public view returns (Vesting memory) {
        return abi.decode(key.read(), (Vesting));
    }

    /// @dev Writes the Config struct to combined storage
    function _setConfig(bytes32 key, Config memory config) internal {
        key.write(abi.encode(config));
    }

    /// @dev Writes the Vesting struct to combined storage
    function _setVesting(bytes32 key, Vesting memory vesting) internal {
        key.write(abi.encode(vesting));
    }
}

/// @title LightVesting Contract
/// @notice Contract for creating and withdrawing token vesting schedules
contract LightVesting is LightStorageIntegration {
    using SafeERC20 for IERC20;

    uint256 public constant DENOM = 100000; // 100%
    uint256 public constant MAX_FEE = 1000; // 1%
    uint256 public constant START_GAP = 50 * 52 weeks; // 50 years

    error NotAdmin(address caller, address admin);

    error TokenMismatch(IERC20 token, IERC20 configured);
    error FeeOverMax(uint256 fee, uint256 max);
    error PercentOverMax(uint256 percent, uint256 max);

    error CliffOverMax(uint256 cliff, uint256 max);
    error AmountOverMax(uint256 amount, uint256 max);
    error DurationOverMax(uint256 duration, uint256 max);
    error StartOverMax(uint256 start, uint256 max);

    error VestingAlreadyExist(bytes32 key);
    error NotBeneficiary(address caller, address beneficiary);

    event Configuration(Config config, bool adminChanged);
    event VestingCreate(bytes32 indexed key, Vesting vesting, uint256 fee);
    event VestingClaim(bytes32 indexed key, Vesting vesting, uint256 unlocked);

    /// @notice Constructor to initialize the contract with a Config struct
    constructor(Config memory config) {
        require(config.admin == msg.sender, NotAdmin(msg.sender, config.admin));
        require(config.fee <= MAX_FEE, FeeOverMax(config.fee, MAX_FEE));
        require(config.maxCliffPercent <= DENOM, PercentOverMax(config.maxCliffPercent, DENOM));

        _setConfig(CONFIG_KEY, config);

        emit Configuration(config, true);
    }

    /// @notice Update the vesting creation rules
    function configurate(Config memory updated) public {
        Config memory config = getConfig(CONFIG_KEY);

        require(config.admin == msg.sender, NotAdmin(msg.sender, config.admin));
        require(config.token == updated.token, TokenMismatch(updated.token, config.token));
        require(updated.fee <= MAX_FEE, FeeOverMax(updated.fee, MAX_FEE));
        require(updated.maxCliffPercent <= DENOM, PercentOverMax(updated.maxCliffPercent, DENOM));

        _setConfig(CONFIG_KEY, updated);

        emit Configuration(config, config.admin != updated.admin);
    }

    /// @notice EOA `configurate` function endpoint
    function configurate(Config memory updated, Config memory config) external {
        loadConfig(CONFIG_KEY, config);
        configurate(updated);
    }

    /// @notice Create a new vesting schedule
    /// @return key The key associated with the newly created vesting
    function create(
        address beneficiary,
        uint256 nonce,
        uint256 amount,
        uint256 start,
        uint256 duration,
        uint256 cliff
    ) public returns (bytes32 key) {
        key = keccak256(abi.encode(VESTING_KEY, beneficiary, msg.sender, nonce));
        require((keyStatus(key) == KeyStatus.Empty), VestingAlreadyExist(key));

        Config memory config = getConfig(CONFIG_KEY);

        require(config.maxAmount >= amount, AmountOverMax(amount, config.maxAmount));
        require(config.maxDuration >= duration, DurationOverMax(duration, config.maxDuration));

        uint256 maxStart = block.timestamp + START_GAP;
        require(maxStart >= start, StartOverMax(start, maxStart));

        /// @dev In case of misconfiguration `duration * config.maxCliffPercent` may overflow
        uint256 maxCliff = (duration * config.maxCliffPercent) / DENOM;
        require(maxCliff >= cliff, CliffOverMax(cliff, maxCliff));

        uint256 fee = (amount * config.fee) / DENOM;

        Vesting memory vesting = Vesting(beneficiary, amount - fee, 0, start, duration, cliff);
        _setVesting(key, vesting);

        config.token.safeTransferFrom(msg.sender, address(this), amount);
        config.token.safeTransfer(config.admin, fee);

        emit VestingCreate(key, vesting, fee);
    }

    /// @notice EOA `create` function endpoint
    function create(
        address beneficiary,
        uint256 nonce,
        uint256 amount,
        uint256 start,
        uint256 duration,
        uint256 cliff,
        Config memory config
    ) external returns (bytes32 key) {
        loadConfig(CONFIG_KEY, config);
        return create(beneficiary, nonce, amount, start, duration, cliff);
    }

    /// @dev Calculates the total amount of tokens vested based on the current time
    function _calcTotalVested(
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 amount
    ) internal view returns (uint256) {
        /// @dev In case of misconfiguration `start + duration` may overflow
        if (block.timestamp >= start + duration) {
            return amount;
        } else if (block.timestamp < start + cliff) {
            return 0;
        } else {
            /// @dev In case of misconfiguration `amount * timePassed` may overflow
            return (amount * (block.timestamp - start)) / duration;
        }
    }

    /// @dev Calculates the amount of tokens that can be withdrawn at the moment
    function _calcWithdrawable(Vesting memory vesting) internal view returns (uint256) {
        uint256 vestedAmount = _calcTotalVested(vesting.start, vesting.cliff, vesting.duration, vesting.amount);
        return vestedAmount - vesting.claimed;
    }

    /// @notice Retrieve the amount of tokens that can be withdrawn by the beneficiary at the moment
    /// @return The amount of tokens that can be withdrawn
    function withdrawable(bytes32 key) public view returns (uint256) {
        return _calcWithdrawable(getVesting(key));
    }

    /// @notice EOA `withdrawable` function endpoint
    function withdrawable(bytes32 key, Vesting memory vesting) external returns (uint256) {
        loadVesting(key, vesting);
        return withdrawable(key);
    }

    /// @notice Allow the beneficiary to withdraw vested tokens
    function withdraw(bytes32 key) public {
        Vesting memory vesting = getVesting(key);
        require(vesting.user == msg.sender, NotBeneficiary(msg.sender, vesting.user));

        Config memory config = getConfig(CONFIG_KEY);

        uint256 unlocked = _calcWithdrawable(vesting);
        vesting.claimed += unlocked;

        _setVesting(key, vesting);

        config.token.safeTransfer(msg.sender, unlocked);

        emit VestingClaim(key, vesting, unlocked);
    }

    /// @notice EOA `withdraw` function endpoint
    function withdraw(bytes32 key, Config memory config, Vesting memory vesting) external {
        loadConfig(CONFIG_KEY, config);
        loadVesting(key, vesting);
        withdraw(key);
    }
}
