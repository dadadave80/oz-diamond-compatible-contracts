// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibVestingWallet} from "@diamond/finance/libraries/LibVestingWallet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev The specified cliff duration is larger than the vesting duration.
error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.VestingWalletCliff")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant VestingWalletCliffStorageLocation = 0x0a0ceb66c7c9aef32c0bfc43d3108868a39e95e96162520745e462557492f100;

/// @custom:storage-location erc7201:openzeppelin.storage.VestingWalletCliff
struct VestingWalletCliffStorage {
    uint64 cliff;
}

library LibVestingWalletCliff {
    using SafeCast for uint256;

    function _vestingWalletCliffStorage() internal pure returns (VestingWalletCliffStorage storage vwc_) {
        assembly {
            vwc_.slot := VestingWalletCliffStorageLocation
        }
    }

    function _init(uint64 cliffSeconds) internal {
        uint256 duration = LibVestingWallet._duration();
        if (cliffSeconds > duration) {
            revert InvalidCliffDuration(cliffSeconds, duration.toUint64());
        }
        _vestingWalletCliffStorage().cliff = LibVestingWallet._start().toUint64() + cliffSeconds;
    }

    function _cliff() internal view returns (uint256) {
        return _vestingWalletCliffStorage().cliff;
    }
}
