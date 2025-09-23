// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable2Step")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant OWNABLE2STEP_STORAGE_SLOT = 0x237e158222e3e6968b72b9db0d8043aacf074ad9f650f0d1606b4d82ee432c00;

/// @custom:storage-location erc7201:openzeppelin.storage.Ownable2Step
struct Ownable2StepStorage {
    address pendingOwner;
}

library LibOwnable2Step {
    function _ownable2StepStorage() internal pure returns (Ownable2StepStorage storage os_) {
        assembly {
            os_.slot := OWNABLE2STEP_STORAGE_SLOT
        }
    }

    function _pendingOwner() internal view returns (address) {
        return _ownable2StepStorage().pendingOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        delete _ownable2StepStorage().pendingOwner;
        LibOwnable._transferOwnership(newOwner);
    }
}
