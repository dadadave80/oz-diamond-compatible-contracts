// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ACCESS_CONTROL_MIXIN_STORAGE_SLOT,
    AccessControlMixinStorage,
    DEFAULT_ADMIN_ROLE
} from "@diamond/access/libraries/storage/AccessControlMixinStorage.sol";

import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibAccessControlMixin {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeCast for uint256;

    function _accessControlMixinStorage() internal pure returns (AccessControlMixinStorage storage acs_) {
        assembly {
            acs_.slot := ACCESS_CONTROL_MIXIN_STORAGE_SLOT
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                       ACCESS CONTROL ROLE MANAGEMENT
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal {
        bytes32 previousAdminRole = _getRoleAdmin(_role);
        _accessControlMixinStorage().roles[_role].adminRole = _adminRole;
        emit IAccessControl.RoleAdminChanged(_role, previousAdminRole, _adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 _role, address _account) internal returns (bool) {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        if (!_hasRole(_role, _account)) {
            if (_role == DEFAULT_ADMIN_ROLE) {
                if (_defaultAdmin() != address(0)) {
                    revert IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules();
                }
                acs.currentDefaultAdmin = _account;
            }
            acs.roles[_role].roleMembers.add(_account);
            emit IAccessControl.RoleGranted(_role, _account, LibContext._msgSender());
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
    function _revokeRole(bytes32 _role, address _account) internal returns (bool) {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        if (_hasRole(_role, _account)) {
            if (_role == DEFAULT_ADMIN_ROLE && _account == _defaultAdmin()) {
                delete acs.currentDefaultAdmin;
            }
            acs.roles[_role].roleMembers.remove(_account);
            emit IAccessControl.RoleRevoked(_role, _account, LibContext._msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     *
     * For the `DEFAULT_ADMIN_ROLE`, it only allows renouncing in two steps by first calling
     * {beginDefaultAdminTransfer} to the `address(0)`, so it's required that the {pendingDefaultAdmin} schedule
     * has also passed when calling this function.
     *
     * After its execution, it will not be possible to call `onlyRole(DEFAULT_ADMIN_ROLE)` functions.
     *
     * NOTE: Renouncing `DEFAULT_ADMIN_ROLE` will leave the contract without a {defaultAdmin},
     * thereby disabling any functionality that is only available for it, and the possibility of reassigning a
     * non-administrated role.
     */
    function _renounceRole(bytes32 _role, address _account) internal {
        if (_account != LibContext._msgSender()) revert IAccessControl.AccessControlBadConfirmation();
        if (_role == DEFAULT_ADMIN_ROLE && _account == _defaultAdmin()) {
            (address newDefaultAdmin, uint48 schedule) = _pendingDefaultAdmin();
            if (newDefaultAdmin != address(0) || !_isScheduleSet(schedule) || !_hasSchedulePassed(schedule)) {
                revert IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay(schedule);
            }
            delete _accessControlMixinStorage().pendingDefaultAdminSchedule;
        }

        _revokeRole(_role, _account);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                   DEFAULT ADMIN / PENDING DEFAULT ADMIN
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev See {beginDefaultAdminTransfer} in AccessControlMixin.
     *
     * Internal function without access restriction.
     */
    function _beginDefaultAdminTransfer(address _newAdmin) internal {
        uint48 newSchedule = (block.timestamp + _defaultAdminDelay()).toUint48();
        _setPendingDefaultAdmin(_newAdmin, newSchedule);
        emit IAccessControlDefaultAdminRules.DefaultAdminTransferScheduled(_newAdmin, newSchedule);
    }

    /**
     * @dev See {cancelDefaultAdminTransfer} in AccessControlMixin.
     *
     * Internal function without access restriction.
     */
    function _cancelDefaultAdminTransfer() internal {
        _setPendingDefaultAdmin(address(0), 0);
    }

    /**
     * @dev See {acceptDefaultAdminTransfer} in AccessControlMixin.
     *
     * Internal function without access restriction.
     */
    function _acceptDefaultAdminTransfer() internal {
        (address newDefaultAdmin, uint48 schedule) = _pendingDefaultAdmin();
        if (LibContext._msgSender() != newDefaultAdmin) {
            // Enforce newDefaultAdmin explicit acceptance.
            revert IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin(LibContext._msgSender());
        }
        if (!_isScheduleSet(schedule) || !_hasSchedulePassed(schedule)) {
            revert IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay(schedule);
        }
        _revokeRole(DEFAULT_ADMIN_ROLE, _defaultAdmin());
        _grantRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        delete acs.pendingDefaultAdmin;
        delete acs.pendingDefaultAdminSchedule;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //             DEFAULT ADMIN DELAY / PENDING DEFAULT ADMIN DELAY
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev See {changeDefaultAdminDelay} in AccessControlMixin.
     *
     * Internal function without access restriction.
     */
    function _changeDefaultAdminDelay(uint48 _newDelay) internal {
        uint48 newSchedule = (block.timestamp + _delayChangeWait(_newDelay)).toUint48();
        _setPendingDelay(_newDelay, newSchedule);
        emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeScheduled(_newDelay, newSchedule);
    }

    /**
     * @dev See {rollbackDefaultAdminDelay} in AccessControlMixin.
     *
     * Internal function without access restriction.
     */
    function _rollbackDefaultAdminDelay() internal {
        _setPendingDelay(0, 0);
    }

    /**
     * @dev Returns the amount of seconds to wait after the `newDelay` will
     * become the new {defaultAdminDelay}.
     *
     * The value returned guarantees that if the delay is reduced, it will go into effect
     * after a wait that honors the previously set delay.
     *
     * See {defaultAdminDelayIncreaseWait} in AccessControlMixin.
     */
    function _delayChangeWait(uint48 _newDelay) internal view returns (uint48) {
        uint48 currentDelay = _defaultAdminDelay();

        // When increasing the delay, we schedule the delay change to occur after a period of "new delay" has passed, up
        // to a maximum given by defaultAdminDelayIncreaseWait, by default 5 days. For example, if increasing from 1 day
        // to 3 days, the new delay will come into effect after 3 days. If increasing from 1 day to 10 days, the new
        // delay will come into effect after 5 days. The 5 day wait period is intended to be able to fix an error like
        // using milliseconds instead of seconds.
        //
        // When decreasing the delay, we wait the difference between "current delay" and "new delay". This guarantees
        // that an admin transfer cannot be made faster than "current delay" at the time the delay change is scheduled.
        // For example, if decreasing from 10 days to 3 days, the new delay will come into effect after 7 days.
        return _newDelay > currentDelay
            ? uint48(Math.min(_newDelay, _defaultAdminDelayIncreaseWait())) // no need to safecast, both inputs are uint48
            : currentDelay - _newDelay;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        return _accessControlMixinStorage().roles[_role].roleMembers.contains(_account);
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
        return _accessControlMixinStorage().roles[_role].adminRole;
    }

    /**
     * @dev Returns the address of the current `DEFAULT_ADMIN_ROLE` holder.
     */
    function _defaultAdmin() internal view returns (address) {
        return _accessControlMixinStorage().currentDefaultAdmin;
    }

    /**
     * @dev Returns a tuple of a `newAdmin` and an accept schedule.
     *
     * After the `schedule` passes, the `newAdmin` will be able to accept the {defaultAdmin} role
     * by calling {acceptDefaultAdminTransfer}, completing the role transfer.
     *
     * A zero value only in `acceptSchedule` indicates no pending admin transfer.
     *
     * NOTE: A zero address `newAdmin` means that {defaultAdmin} is being renounced.
     */
    function _pendingDefaultAdmin() internal view returns (address newAdmin, uint48 schedule) {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        return (acs.pendingDefaultAdmin, acs.pendingDefaultAdminSchedule);
    }

    /**
     * @dev Returns the delay required to schedule the acceptance of a {defaultAdmin} transfer started.
     *
     * This delay will be added to the current timestamp when calling {beginDefaultAdminTransfer} to set
     * the acceptance schedule.
     *
     * NOTE: If a delay change has been scheduled, it will take effect as soon as the schedule passes, making this
     * function returns the new delay. See {changeDefaultAdminDelay}.
     */
    function _defaultAdminDelay() internal view returns (uint48) {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        uint48 schedule = acs.pendingDelaySchedule;
        return (_isScheduleSet(schedule) && _hasSchedulePassed(schedule)) ? acs.pendingDelay : acs.currentDelay;
    }

    /**
     * @dev Returns a tuple of `newDelay` and an effect schedule.
     *
     * After the `schedule` passes, the `newDelay` will get into effect immediately for every
     * new {defaultAdmin} transfer started with {beginDefaultAdminTransfer}.
     *
     * A zero value only in `effectSchedule` indicates no pending delay change.
     *
     * NOTE: A zero value only for `newDelay` means that the next {defaultAdminDelay}
     * will be zero after the effect schedule.
     */
    function _pendingDefaultAdminDelay() internal view returns (uint48 newDelay, uint48 schedule) {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        schedule = acs.pendingDelaySchedule;
        return (_isScheduleSet(schedule) && !_hasSchedulePassed(schedule)) ? (acs.pendingDelay, schedule) : (0, 0);
    }

    /**
     * @dev Maximum time in seconds for an increase to {defaultAdminDelay} (that is scheduled using {changeDefaultAdminDelay})
     * to take effect. Default to 5 days.
     *
     * When the {defaultAdminDelay} is scheduled to be increased, it goes into effect after the new delay has passed with
     * the purpose of giving enough time for reverting any accidental change (i.e. using milliseconds instead of seconds)
     * that may lock the contract. However, to avoid excessive schedules, the wait is capped by this function and it can
     * be overrode for a custom {defaultAdminDelay} increase scheduling.
     *
     * IMPORTANT: Make sure to add a reasonable amount of time while overriding this value, otherwise,
     * there's a risk of setting a high new delay that goes into effect almost immediately without the
     * possibility of human intervention in the case of an input error (eg. set milliseconds instead of seconds).
     */
    function _defaultAdminDelayIncreaseWait() internal pure returns (uint48) {
        return 5 days;
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function _getRoleMember(bytes32 _role, uint256 _index) internal view returns (address) {
        return _accessControlMixinStorage().roles[_role].roleMembers.at(_index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function _getRoleMemberCount(bytes32 _role) internal view returns (uint256) {
        return _accessControlMixinStorage().roles[_role].roleMembers.length();
    }

    /**
     * @dev Return all accounts that have `role`
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _getRoleMembers(bytes32 _role) internal view returns (address[] memory) {
        return _accessControlMixinStorage().roles[_role].roleMembers.values();
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              PRIVATE SETTERS
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev Setter of the tuple for pending admin and its schedule.
     *
     * May emit a DefaultAdminTransferCanceled event.
     */
    function _setPendingDefaultAdmin(address _newAdmin, uint48 _newSchedule) private {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        (, uint48 oldSchedule) = _pendingDefaultAdmin();

        acs.pendingDefaultAdmin = _newAdmin;
        acs.pendingDefaultAdminSchedule = _newSchedule;

        // An `oldSchedule` from `pendingDefaultAdmin()` is only set if it hasn't been accepted.
        if (_isScheduleSet(oldSchedule)) {
            // Emit for implicit cancellations when another default admin was scheduled.
            emit IAccessControlDefaultAdminRules.DefaultAdminTransferCanceled();
        }
    }

    /**
     * @dev Setter of the tuple for pending delay and its schedule.
     *
     * May emit a DefaultAdminDelayChangeCanceled event.
     */
    function _setPendingDelay(uint48 _newDelay, uint48 _newSchedule) private {
        AccessControlMixinStorage storage acs = _accessControlMixinStorage();
        uint48 oldSchedule = acs.pendingDelaySchedule;

        if (_isScheduleSet(oldSchedule)) {
            if (_hasSchedulePassed(oldSchedule)) {
                // Materialize a virtual delay
                acs.currentDelay = acs.pendingDelay;
            } else {
                // Emit for implicit cancellations when another delay was scheduled.
                emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeCanceled();
            }
        }

        acs.pendingDelay = _newDelay;
        acs.pendingDelaySchedule = _newSchedule;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              PRIVATE HELPERS
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev Defines if an `_schedule` is considered set. For consistency purposes.
     */
    function _isScheduleSet(uint48 _schedule) private pure returns (bool) {
        return _schedule != 0;
    }

    /**
     * @dev Defines if an `_schedule` is considered passed. For consistency purposes.
     */
    function _hasSchedulePassed(uint48 _schedule) private view returns (bool) {
        return _schedule < block.timestamp;
    }
}
