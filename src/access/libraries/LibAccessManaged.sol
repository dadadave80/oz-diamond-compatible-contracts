// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AuthorityUtils} from "@openzeppelin/contracts/access/manager/AuthorityUtils.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessManaged")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_MANAGED_STORAGE_SLOT = 0xf3177357ab46d8af007ab3fdb9af81da189e1068fefdc0073dca88a2cab40a00;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessManaged
struct AccessManagedStorage {
    address authority;
    bool consumingSchedule;
}

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
