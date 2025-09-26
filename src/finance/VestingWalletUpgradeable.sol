// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@diamond/access/OwnableUpgradeable.sol";
import {LibVestingWallet} from "@diamond/finance/libraries/LibVestingWallet.sol";
import {Initializable} from "@diamond/utils/initializable/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingWalletUpgradeable is Initializable, OwnableUpgradeable {
    using LibVestingWallet for *;

    constructor() {
        _disableInitializers();
    }

    function initialize(address beneficiary, uint64 startTimestamp, uint64 durationSeconds)
        public
        virtual
        initializer
    {
        __VestingWallet_init(beneficiary, startTimestamp, durationSeconds);
    }

    /**
     * @dev Sets the beneficiary (owner), the start timestamp and the vesting duration (in seconds) of the vesting
     * wallet.
     */
    function __VestingWallet_init(address beneficiary, uint64 startTimestamp, uint64 durationSeconds)
        internal
        onlyInitializing
    {
        __Ownable_init_unchained(beneficiary);
        __VestingWallet_init_unchained(startTimestamp, durationSeconds);
    }

    function __VestingWallet_init_unchained(uint64 startTimestamp, uint64 durationSeconds) internal onlyInitializing {
        startTimestamp._init(durationSeconds);
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view virtual returns (uint256) {
        return LibVestingWallet._start();
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return LibVestingWallet._duration();
    }

    /**
     * @dev Getter for the end timestamp.
     */
    function end() public view virtual returns (uint256) {
        return start() + duration();
    }

    /**
     * @dev Amount of eth already released
     */
    function released() public view virtual returns (uint256) {
        return LibVestingWallet._released();
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return token._released();
    }

    /**
     * @dev Getter for the amount of releasable eth.
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * {IERC20} contract.
     */
    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - released(token);
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public virtual {
        uint256 amount = releasable();
        LibVestingWallet._vestingWalletStorage().released += amount;
        amount._release();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(address token) public virtual {
        uint256 amount = releasable(token);
        LibVestingWallet._vestingWalletStorage().erc20Released[token] += amount;
        token._release(amount);
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(address(this).balance + released(), timestamp);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address token, uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(IERC20(token).balanceOf(address(this)) + released(token), timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp >= end()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }
}
