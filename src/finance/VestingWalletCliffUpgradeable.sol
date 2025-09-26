// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VestingWalletUpgradeable} from "@diamond/finance/VestingWalletUpgradeable.sol";
import {LibVestingWalletCliff} from "@diamond/finance/libraries/LibVestingWalletCliff.sol";
import {Initializable} from "@diamond/utils/initializable/Initializable.sol";

abstract contract VestingWalletCliffUpgradeable is Initializable, VestingWalletUpgradeable {
    using LibVestingWalletCliff for *;

    /**
     * @dev Set the duration of the cliff, in seconds. The cliff starts vesting schedule (see {VestingWallet}'s
     * constructor) and ends `cliffSeconds` later.
     */
    function __VestingWalletCliff_init(uint64 cliffSeconds) internal onlyInitializing {
        __VestingWalletCliff_init_unchained(cliffSeconds);
    }

    function __VestingWalletCliff_init_unchained(uint64 cliffSeconds) internal onlyInitializing {
        cliffSeconds._init();
    }

    /**
     * @dev Getter for the cliff timestamp.
     */
    function cliff() public view virtual returns (uint256) {
        return LibVestingWalletCliff._cliff();
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation. Returns 0 if the {cliff} timestamp is not met.
     *
     * IMPORTANT: The cliff not only makes the schedule return 0, but it also ignores every possible side
     * effect from calling the inherited implementation (i.e. `super._vestingSchedule`). Carefully consider
     * this caveat if the overridden implementation of this function has any (e.g. writing to memory or reverting).
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return timestamp < cliff() ? 0 : super._vestingSchedule(totalAllocation, timestamp);
    }
}
