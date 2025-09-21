// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";
import {
    OWNABLE2STEP_STORAGE_SLOT, Ownable2StepStorage
} from "@diamond/access/libraries/storage/Ownable2StepStorage.sol";

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
