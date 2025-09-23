// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {LibERC165} from "@diamond/utils/introspection/LibERC165.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_CONTROL_STORAGE_SLOT = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
struct AccessControlStorage {
    mapping(bytes32 role => RoleData) roles;
}

struct RoleData {
    mapping(address account => bool) hasRole;
    bytes32 adminRole;
}

library LibAccessControl {
    function _accessControlStorage() internal pure returns (AccessControlStorage storage acs_) {
        assembly {
            acs_.slot := ACCESS_CONTROL_STORAGE_SLOT
        }
    }

    function _init(address admin) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function _registerInterface() internal {
        LibERC165._registerInterface(type(IAccessControl).interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        return _accessControlStorage().roles[_role].hasRole[_account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, LibContext._msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
            revert IAccessControl.AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function _getRoleAdmin(bytes32 _role) internal view returns (bytes32) {
        return _accessControlStorage().roles[_role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        _accessControlStorage().roles[role].adminRole = adminRole;
        emit IAccessControl.RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal returns (bool) {
        if (!_hasRole(role, account)) {
            _accessControlStorage().roles[role].hasRole[account] = true;
            emit IAccessControl.RoleGranted(role, account, LibContext._msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal returns (bool) {
        if (_hasRole(role, account)) {
            _accessControlStorage().roles[role].hasRole[account] = false;
            emit IAccessControl.RoleRevoked(role, account, LibContext._msgSender());
            return true;
        } else {
            return false;
        }
    }

    function _renounceRole(bytes32 role, address callerConfirmation) internal {
        if (callerConfirmation != LibContext._msgSender()) {
            revert IAccessControl.AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }
}
