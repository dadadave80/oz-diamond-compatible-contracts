// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ACCESS_MANAGED_STORAGE_SLOT,
    AccessManagedStorage
} from "@diamond/access/libraries/storage/AccessManagedStorage.sol";

import {AuthorityUtils} from "@openzeppelin/contracts/access/manager/AuthorityUtils.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";

library LibAccessManaged {
    function _accessManagedStorage() internal pure returns (AccessManagedStorage storage ams_) {
        assembly {
            ams_.slot := ACCESS_MANAGED_STORAGE_SLOT
        }
    }

    function _authority() internal view returns (address) {
        return _accessManagedStorage().authority;
    }

    function _isConsumingScheduledOp() internal view returns (bytes4) {
        return _accessManagedStorage().consumingSchedule ? IAccessManaged.isConsumingScheduledOp.selector : bytes4(0);
    }

    /**
     * @dev Transfers control to a new authority. Internal function with no access restriction. Allows bypassing the
     * permissions set by the current authority.
     */
    function _setAuthority(address newAuthority) internal {
        _accessManagedStorage().authority = newAuthority;
        emit IAccessManaged.AuthorityUpdated(newAuthority);
    }

    /**
     * @dev Reverts if the caller is not allowed to call the function identified by a selector. Panics if the calldata
     * is less than 4 bytes long.
     */
    function _checkCanCall(address caller, bytes calldata data) internal {
        AccessManagedStorage storage ams = _accessManagedStorage();
        (bool immediate, uint32 delay) =
            AuthorityUtils.canCallWithDelay(_authority(), caller, address(this), bytes4(data[0:4]));
        if (!immediate) {
            if (delay > 0) {
                ams.consumingSchedule = true;
                IAccessManager(_authority()).consumeScheduledOp(caller, data);
                ams.consumingSchedule = false;
            } else {
                revert IAccessManaged.AccessManagedUnauthorized(caller);
            }
        }
    }
}
