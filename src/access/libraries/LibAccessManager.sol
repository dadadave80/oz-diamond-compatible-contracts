// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ACCESS_MANAGER_STORAGE_SLOT,
    ADMIN_ROLE,
    Access,
    AccessManagerStorage,
    PUBLIC_ROLE
} from "@diamond/access/libraries/storage/AccessManagerStorage.sol";

import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {LibERC165} from "@diamond/utils/introspection/LibERC165.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

library LibAccessManager {
    using Time for *;

    function _accessManagerStorage() internal pure returns (AccessManagerStorage storage ams_) {
        assembly {
            ams_.slot := ACCESS_MANAGER_STORAGE_SLOT
        }
    }

    function _registerInterface() internal {
        LibERC165._registerInterface(type(IAccessManager).interfaceId);
    }

    function _canCall(address _caller, address _target, bytes4 _selector)
        internal
        view
        returns (bool immediate_, uint32 delay_)
    {
        if (_isTargetClosed(_target)) {
            return (false, 0);
        } else if (_caller == address(this)) {
            // Caller is AccessManager, this means the call was sent through {execute} and it already checked
            // permissions. We verify that the call "identifier", which is set during {execute}, is correct.
            return (_isExecuting(_target, _selector), 0);
        } else {
            uint64 roleId = _getTargetFunctionRole(_target, _selector);
            (bool isMember, uint32 currentDelay) = _hasRole(roleId, _caller);
            return isMember ? (currentDelay == 0, currentDelay) : (false, 0);
        }
    }

    function _expiration() internal pure returns (uint32) {
        return 1 weeks;
    }

    function _minSetback() internal pure returns (uint32) {
        return 5 days;
    }

    function _isTargetClosed(address _target) internal view returns (bool) {
        return _accessManagerStorage().targets[_target].closed;
    }

    function _getTargetFunctionRole(address _target, bytes4 _selector) internal view returns (uint64) {
        return _accessManagerStorage().targets[_target].allowedRoles[_selector];
    }

    function _getTargetAdminDelay(address _target) internal view returns (uint32) {
        return _accessManagerStorage().targets[_target].adminDelay.get();
    }

    function _getRoleAdmin(uint64 _roleId) internal view returns (uint64) {
        return _accessManagerStorage().roles[_roleId].admin;
    }

    function _getRoleGuardian(uint64 _roleId) internal view returns (uint64) {
        return _accessManagerStorage().roles[_roleId].guardian;
    }

    function _getRoleGrantDelay(uint64 _roleId) internal view returns (uint32) {
        return _accessManagerStorage().roles[_roleId].grantDelay.get();
    }

    function _getAccess(uint64 _roleId, address _account)
        internal
        view
        returns (uint48 since_, uint32 currentDelay_, uint32 pendingDelay_, uint48 effect_)
    {
        Access memory access = _accessManagerStorage().roles[_roleId].members[_account];

        since_ = access.since;
        (currentDelay_, pendingDelay_, effect_) = access.delay.getFull();
    }

    function _hasRole(uint64 _roleId, address _account)
        internal
        view
        returns (bool isMember_, uint32 executionDelay_)
    {
        if (_roleId == PUBLIC_ROLE) {
            return (true, 0);
        } else {
            (uint48 hasRoleSince, uint32 currentDelay,,) = _getAccess(_roleId, _account);
            isMember_ = hasRoleSince != 0 && hasRoleSince <= Time.timestamp();
            executionDelay_ = currentDelay;
        }
    }

    function _labelRole(uint64 _roleId, string calldata _label) internal {
        if (_roleId == ADMIN_ROLE || _roleId == PUBLIC_ROLE) {
            revert IAccessManager.AccessManagerLockedRole(_roleId);
        }
        emit IAccessManager.RoleLabel(_roleId, _label);
    }

    function _renounceRole(uint64 roleId, address callerConfirmation) internal {
        if (callerConfirmation != LibContext._msgSender()) {
            revert IAccessManager.AccessManagerBadConfirmation();
        }
        _revokeRole(roleId, callerConfirmation);
    }

    /**
     * @dev Internal version of {grantRole} without access control. Returns true if the role was newly granted.
     *
     * Emits a {RoleGranted} event.
     */
    function _grantRole(uint64 _roleId, address _account, uint32 _grantDelay, uint32 _executionDelay)
        internal
        returns (bool newMember_)
    {
        if (_roleId == PUBLIC_ROLE) revert IAccessManager.AccessManagerLockedRole(_roleId);

        AccessManagerStorage storage ams = _accessManagerStorage();
        newMember_ = ams.roles[_roleId].members[_account].since == 0;
        uint48 since;

        if (newMember_) {
            since = Time.timestamp() + _grantDelay;
            ams.roles[_roleId].members[_account] = Access({since: since, delay: _executionDelay.toDelay()});
        } else {
            // No setback here. Value can be reset by doing revoke + grant, effectively allowing the admin to perform
            // any change to the execution delay within the duration of the role admin delay.
            (ams.roles[_roleId].members[_account].delay, since) =
                ams.roles[_roleId].members[_account].delay.withUpdate(_executionDelay, 0);
        }

        emit IAccessManager.RoleGranted(_roleId, _account, _executionDelay, since, newMember_);
    }

    /**
     * @dev Internal version of {revokeRole} without access control. This logic is also used by {renounceRole}.
     * Returns true if the role was previously granted.
     *
     * Emits a {RoleRevoked} event if the account had the role.
     */
    function _revokeRole(uint64 _roleId, address _account) internal returns (bool) {
        if (_roleId == PUBLIC_ROLE) {
            revert IAccessManager.AccessManagerLockedRole(_roleId);
        }

        AccessManagerStorage storage ams = _accessManagerStorage();
        if (ams.roles[_roleId].members[_account].since == 0) {
            return false;
        }

        delete ams.roles[_roleId].members[_account];

        emit IAccessManager.RoleRevoked(_roleId, _account);
        return true;
    }

    /**
     * @dev Internal version of {setRoleAdmin} without access control.
     *
     * Emits a {RoleAdminChanged} event.
     *
     * NOTE: Setting the admin role as the `PUBLIC_ROLE` is allowed, but it will effectively allow
     * anyone to set grant or revoke such role.
     */
    function _setRoleAdmin(uint64 _roleId, uint64 _admin) internal {
        if (_roleId == ADMIN_ROLE || _roleId == PUBLIC_ROLE) {
            revert IAccessManager.AccessManagerLockedRole(_roleId);
        }

        _accessManagerStorage().roles[_roleId].admin = _admin;

        emit IAccessManager.RoleAdminChanged(_roleId, _admin);
    }

    /**
     * @dev Internal version of {setRoleGuardian} without access control.
     *
     * Emits a {RoleGuardianChanged} event.
     *
     * NOTE: Setting the guardian role as the `PUBLIC_ROLE` is allowed, but it will effectively allow
     * anyone to cancel any scheduled operation for such role.
     */
    function _setRoleGuardian(uint64 _roleId, uint64 _guardian) internal {
        if (_roleId == ADMIN_ROLE || _roleId == PUBLIC_ROLE) {
            revert IAccessManager.AccessManagerLockedRole(_roleId);
        }

        _accessManagerStorage().roles[_roleId].guardian = _guardian;

        emit IAccessManager.RoleGuardianChanged(_roleId, _guardian);
    }

    /**
     * @dev Internal version of {setGrantDelay} without access control.
     *
     * Emits a {RoleGrantDelayChanged} event.
     */
    function _setGrantDelay(uint64 _roleId, uint32 _newDelay) internal {
        if (_roleId == PUBLIC_ROLE) {
            revert IAccessManager.AccessManagerLockedRole(_roleId);
        }

        AccessManagerStorage storage ams = _accessManagerStorage();
        uint48 effect;
        (ams.roles[_roleId].grantDelay, effect) = ams.roles[_roleId].grantDelay.withUpdate(_newDelay, _minSetback());

        emit IAccessManager.RoleGrantDelayChanged(_roleId, _newDelay, effect);
    }

    /**
     * @dev Internal version of {setTargetFunctionRole} without access control.
     *
     * Emits a {TargetFunctionRoleUpdated} event.
     */
    function _setTargetFunctionRole(address _target, bytes4 _selector, uint64 _roleId) internal {
        _accessManagerStorage().targets[_target].allowedRoles[_selector] = _roleId;
        emit IAccessManager.TargetFunctionRoleUpdated(_target, _selector, _roleId);
    }

    /**
     * @dev Internal version of {setTargetAdminDelay} without access control.
     *
     * Emits a {TargetAdminDelayUpdated} event.
     */
    function _setTargetAdminDelay(address _target, uint32 _newDelay) internal {
        AccessManagerStorage storage ams = _accessManagerStorage();
        uint48 effect;
        (ams.targets[_target].adminDelay, effect) = ams.targets[_target].adminDelay.withUpdate(_newDelay, _minSetback());

        emit IAccessManager.TargetAdminDelayUpdated(_target, _newDelay, effect);
    }

    /**
     * @dev Set the closed flag for a contract. This is an internal setter with no access restrictions.
     *
     * Emits a {TargetClosed} event.
     */
    function _setTargetClosed(address _target, bool _closed) internal {
        _accessManagerStorage().targets[_target].closed = _closed;
        emit IAccessManager.TargetClosed(_target, _closed);
    }

    function _getSchedule(bytes32 _id) internal view returns (uint48) {
        uint48 timepoint = _accessManagerStorage().schedules[_id].timepoint;
        return _isExpired(timepoint) ? 0 : timepoint;
    }

    function _getNonce(bytes32 _id) internal view returns (uint32) {
        return _accessManagerStorage().schedules[_id].nonce;
    }

    function _schedule(address _target, bytes calldata _data, uint48 _when)
        internal
        returns (bytes32 operationId_, uint32 nonce_)
    {
        address caller = LibContext._msgSender();

        // Fetch restrictions that apply to the caller on the targeted function
        (, uint32 setback) = _canCallExtended(caller, _target, _data);

        uint48 minWhen = Time.timestamp() + setback;

        // If call with delay is not authorized, or if requested timing is too soon, revert
        if (setback == 0 || (_when > 0 && _when < minWhen)) {
            revert IAccessManager.AccessManagerUnauthorizedCall(caller, _target, _checkSelector(_data));
        }

        // Reuse variable due to stack too deep
        _when = uint48(Math.max(_when, minWhen)); // cast is safe: both inputs are uint48

        // If caller is authorised, schedule operation
        operationId_ = _hashOperation(caller, _target, _data);

        _checkNotScheduled(operationId_);

        AccessManagerStorage storage ams = _accessManagerStorage();
        unchecked {
            // It's not feasible to overflow the nonce in less than 1000 years
            nonce_ = ams.schedules[operationId_].nonce + 1;
        }
        ams.schedules[operationId_].timepoint = _when;
        ams.schedules[operationId_].nonce = nonce_;
        emit IAccessManager.OperationScheduled(operationId_, nonce_, _when, caller, _target, _data);

        // Using named return values because otherwise we get stack too deep
    }

    function _execute(address _target, bytes calldata _data) internal returns (uint32 nonce_) {
        address caller = LibContext._msgSender();

        // Fetch restrictions that apply to the caller on the targeted function
        (bool immediate, uint32 setback) = _canCallExtended(caller, _target, _data);

        // If call is not authorized, revert
        if (!immediate && setback == 0) {
            revert IAccessManager.AccessManagerUnauthorizedCall(caller, _target, _checkSelector(_data));
        }

        bytes32 operationId = _hashOperation(caller, _target, _data);

        // If caller is authorised, check operation was scheduled early enough
        // Consume an available schedule even if there is no currently enforced delay
        if (setback != 0 || _getSchedule(operationId) != 0) {
            nonce_ = _consumeScheduledOp(operationId);
        }

        AccessManagerStorage storage ams = _accessManagerStorage();
        // Mark the target and selector as authorised
        bytes32 executionIdBefore = ams.executionId;
        ams.executionId = _hashExecutionId(_target, _checkSelector(_data));

        // Perform call
        Address.functionCallWithValue(_target, _data, msg.value);

        // Reset execute identifier
        ams.executionId = executionIdBefore;
    }

    function _cancel(address caller, address target, bytes calldata data) internal returns (uint32 nonce_) {
        address msgsender = LibContext._msgSender();
        bytes4 selector = _checkSelector(data);

        bytes32 operationId = _hashOperation(caller, target, data);
        AccessManagerStorage storage ams = _accessManagerStorage();
        if (ams.schedules[operationId].timepoint == 0) {
            revert IAccessManager.AccessManagerNotScheduled(operationId);
        } else if (caller != msgsender) {
            // calls can only be canceled by the account that scheduled them, a global admin, or by a guardian of the required role.
            (bool isAdmin,) = _hasRole(ADMIN_ROLE, msgsender);
            (bool isGuardian,) = _hasRole(_getRoleGuardian(_getTargetFunctionRole(target, selector)), msgsender);
            if (!isAdmin && !isGuardian) {
                revert IAccessManager.AccessManagerUnauthorizedCancel(msgsender, caller, target, selector);
            }
        }

        delete ams.schedules[operationId].timepoint; // reset the timepoint, keep the nonce
        nonce_ = ams.schedules[operationId].nonce;
        emit IAccessManager.OperationCanceled(operationId, nonce_);
    }

    function _consumeScheduledOp(address _caller, bytes calldata _data) internal {
        address target = LibContext._msgSender();
        if (IAccessManaged(target).isConsumingScheduledOp() != IAccessManaged.isConsumingScheduledOp.selector) {
            revert IAccessManager.AccessManagerUnauthorizedConsume(target);
        }
        _consumeScheduledOp(_hashOperation(_caller, target, _data));
    }

    /**
     * @dev Internal variant of {consumeScheduledOp} that operates on bytes32 operationId.
     *
     * Returns the nonce of the scheduled operation that is consumed.
     */
    function _consumeScheduledOp(bytes32 _operationId) internal returns (uint32 nonce_) {
        AccessManagerStorage storage ams = _accessManagerStorage();
        uint48 timepoint = ams.schedules[_operationId].timepoint;
        nonce_ = ams.schedules[_operationId].nonce;

        if (timepoint == 0) {
            revert IAccessManager.AccessManagerNotScheduled(_operationId);
        } else if (timepoint > Time.timestamp()) {
            revert IAccessManager.AccessManagerNotReady(_operationId);
        } else if (_isExpired(timepoint)) {
            revert IAccessManager.AccessManagerExpired(_operationId);
        }

        delete ams.schedules[_operationId].timepoint; // reset the timepoint, keep the nonce
        emit IAccessManager.OperationExecuted(_operationId, nonce_);
    }

    function _hashOperation(address _caller, address _target, bytes calldata _data) internal pure returns (bytes32) {
        return keccak256(abi.encode(_caller, _target, _data));
    }

    function _updateAuthority(address _target, address _newAuthority) internal {
        IAccessManaged(_target).setAuthority(_newAuthority);
    }

    /**
     * @dev Check if the current call is authorized according to admin and roles logic.
     *
     * WARNING: Carefully review the considerations of {AccessManaged-restricted} since they apply to this modifier.
     */
    function _checkAuthorized() internal {
        address caller = LibContext._msgSender();
        (bool immediate, uint32 delay) = _canCallSelf(caller, LibContext._msgData());
        if (!immediate) {
            if (delay == 0) {
                (, uint64 requiredRole,) = _getAdminRestrictions(LibContext._msgData());
                revert IAccessManager.AccessManagerUnauthorizedAccount(caller, requiredRole);
            } else {
                _consumeScheduledOp(_hashOperation(caller, address(this), LibContext._msgData()));
            }
        }
    }

    /**
     * @dev Get the admin restrictions of a given function call based on the function and arguments involved.
     *
     * Returns:
     * - bool restricted: does this data match a restricted operation
     * - uint64: which role is this operation restricted to
     * - uint32: minimum delay to enforce for that operation (max between operation's delay and admin's execution delay)
     */
    function _getAdminRestrictions(bytes calldata _data)
        private
        view
        returns (bool adminRestricted_, uint64 roleAdminId_, uint32 executionDelay_)
    {
        if (_data.length < 4) {
            return (false, 0, 0);
        }

        bytes4 selector = _checkSelector(_data);

        // Restricted to ADMIN with no delay beside any execution delay the caller may have
        if (
            selector == IAccessManager.labelRole.selector || selector == IAccessManager.setRoleAdmin.selector
                || selector == IAccessManager.setRoleGuardian.selector || selector == IAccessManager.setGrantDelay.selector
                || selector == IAccessManager.setTargetAdminDelay.selector
        ) {
            return (true, ADMIN_ROLE, 0);
        }

        // Restricted to ADMIN with the admin delay corresponding to the target
        if (
            selector == IAccessManager.updateAuthority.selector || selector == IAccessManager.setTargetClosed.selector
                || selector == IAccessManager.setTargetFunctionRole.selector
        ) {
            // First argument is a target.
            address target = abi.decode(_data[0x04:0x24], (address));
            uint32 delay = _getTargetAdminDelay(target);
            return (true, ADMIN_ROLE, delay);
        }

        // Restricted to that role's admin with no delay beside any execution delay the caller may have.
        if (selector == IAccessManager.grantRole.selector || selector == IAccessManager.revokeRole.selector) {
            // First argument is a roleId.
            uint64 roleId = abi.decode(_data[0x04:0x24], (uint64));
            return (true, _getRoleAdmin(roleId), 0);
        }

        return (false, _getTargetFunctionRole(address(this), selector), 0);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                              PRIVATE HELPERS
    //////////////////////////////////////////////////////////////////////////*//

    /**
     * @dev Reverts if the operation is currently scheduled and has not expired.
     *
     * NOTE: This function was introduced due to stack too deep errors in schedule.
     */
    function _checkNotScheduled(bytes32 _operationId) private view {
        uint48 prevTimepoint = _accessManagerStorage().schedules[_operationId].timepoint;
        if (prevTimepoint != 0 && !_isExpired(prevTimepoint)) {
            revert IAccessManager.AccessManagerAlreadyScheduled(_operationId);
        }
    }

    /**
     * @dev An extended version of {canCall} for internal usage that checks {_canCallSelf}
     * when the target is this contract.
     *
     * Returns:
     * - bool immediate: whether the operation can be executed immediately (with no delay)
     * - uint32 delay: the execution delay
     */
    function _canCallExtended(address _caller, address _target, bytes calldata _data)
        private
        view
        returns (bool immediate_, uint32 delay_)
    {
        if (_target == address(this)) {
            return _canCallSelf(_caller, _data);
        } else {
            return _data.length < 4 ? (false, 0) : _canCall(_caller, _target, _checkSelector(_data));
        }
    }

    /**
     * @dev A version of {canCall} that checks for restrictions in this contract.
     */
    function _canCallSelf(address _caller, bytes calldata _data)
        private
        view
        returns (bool immediate_, uint32 delay_)
    {
        if (_data.length < 4) {
            return (false, 0);
        }

        if (_caller == address(this)) {
            // Caller is AccessManager, this means the call was sent through {execute} and it already checked
            // permissions. We verify that the call "identifier", which is set during {execute}, is correct.
            return (_isExecuting(address(this), _checkSelector(_data)), 0);
        }

        (bool adminRestricted, uint64 roleId, uint32 operationDelay) = _getAdminRestrictions(_data);

        // isTargetClosed apply to non-admin-restricted function
        if (!adminRestricted && _isTargetClosed(address(this))) {
            return (false, 0);
        }

        (bool inRole, uint32 executionDelay) = _hasRole(roleId, _caller);
        if (!inRole) {
            return (false, 0);
        }

        // downcast is safe because both options are uint32
        delay_ = uint32(Math.max(operationDelay, executionDelay));
        return (delay_ == 0, delay_);
    }

    /**
     * @dev Returns true if a call with `target` and `selector` is being executed via {executed}.
     */
    function _isExecuting(address target, bytes4 selector) internal view returns (bool) {
        return _accessManagerStorage().executionId == _hashExecutionId(target, selector);
    }

    /**
     * @dev Returns true if a schedule timepoint is past its expiration deadline.
     */
    function _isExpired(uint48 timepoint) private view returns (bool) {
        return timepoint + _expiration() <= Time.timestamp();
    }

    /**
     * @dev Extracts the selector from calldata. Panics if data is not at least 4 bytes
     */
    function _checkSelector(bytes calldata data) private pure returns (bytes4) {
        return bytes4(data[0:4]);
    }

    /**
     * @dev Hashing function for execute protection
     */
    function _hashExecutionId(address target, bytes4 selector) private pure returns (bytes32) {
        return keccak256(abi.encode(target, selector));
    }
}
