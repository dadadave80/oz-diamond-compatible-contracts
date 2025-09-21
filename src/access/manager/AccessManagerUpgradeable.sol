// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ADMIN_ROLE, LibAccessManager, PUBLIC_ROLE} from "@diamond/access/libraries/LibAccessManager.sol";
import {ContextUpgradeable} from "@diamond/utils/context/ContextUpgradeable.sol";
import {Initializable} from "@diamond/utils/initializable/Initializable.sol";
import {MulticallUpgradeable} from "@diamond/utils/multicall/MulticallUpgradeable.sol";
import {IAccessManaged} from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

abstract contract AccessManagerUpgradeable is
    Initializable,
    ContextUpgradeable,
    MulticallUpgradeable,
    IAccessManager
{
    using LibAccessManager for *;

    /**
     * @dev Check that the caller is authorized to perform the operation.
     * See {AccessManager} description for a detailed breakdown of the authorization logic.
     */
    modifier onlyAuthorized() {
        _checkAuthorized();
        _;
    }

    function initialize(address initialAdmin) public virtual initializer {
        __AccessManager_init(initialAdmin);
    }

    function __AccessManager_init(address initialAdmin) internal onlyInitializing {
        __AccessManager_init_unchained(initialAdmin);
    }

    function __AccessManager_init_unchained(address initialAdmin) internal onlyInitializing {
        if (initialAdmin == address(0)) {
            revert AccessManagerInvalidInitialAdmin(address(0));
        }

        // admin is active immediately and without any execution delay.
        _grantRole(ADMIN_ROLE, initialAdmin, 0, 0);
    }

    // =================================================== GETTERS ====================================================
    /// @inheritdoc IAccessManager
    function canCall(address caller, address target, bytes4 selector)
        public
        view
        virtual
        returns (bool immediate, uint32 delay)
    {
        if (isTargetClosed(target)) {
            return (false, 0);
        } else if (caller == address(this)) {
            // Caller is AccessManager, this means the call was sent through {execute} and it already checked
            // permissions. We verify that the call "identifier", which is set during {execute}, is correct.
            return (target._isExecuting(selector), 0);
        } else {
            uint64 roleId = getTargetFunctionRole(target, selector);
            (bool isMember, uint32 currentDelay) = hasRole(roleId, caller);
            return isMember ? (currentDelay == 0, currentDelay) : (false, 0);
        }
    }

    /// @inheritdoc IAccessManager
    function expiration() public view virtual returns (uint32) {
        return LibAccessManager._expiration();
    }

    /// @inheritdoc IAccessManager
    function minSetback() public view virtual returns (uint32) {
        return LibAccessManager._minSetback();
    }

    /// @inheritdoc IAccessManager
    function isTargetClosed(address target) public view virtual returns (bool) {
        return target._isTargetClosed();
    }

    /// @inheritdoc IAccessManager
    function getTargetFunctionRole(address target, bytes4 selector) public view virtual returns (uint64) {
        return target._getTargetFunctionRole(selector);
    }

    /// @inheritdoc IAccessManager
    function getTargetAdminDelay(address target) public view virtual returns (uint32) {
        return target._getTargetAdminDelay();
    }

    /// @inheritdoc IAccessManager
    function getRoleAdmin(uint64 roleId) public view virtual returns (uint64) {
        return roleId._getRoleAdmin();
    }

    /// @inheritdoc IAccessManager
    function getRoleGuardian(uint64 roleId) public view virtual returns (uint64) {
        return roleId._getRoleGuardian();
    }

    /// @inheritdoc IAccessManager
    function getRoleGrantDelay(uint64 roleId) public view virtual returns (uint32) {
        return roleId._getRoleGrantDelay();
    }

    /// @inheritdoc IAccessManager
    function getAccess(uint64 roleId, address account)
        public
        view
        virtual
        returns (uint48 since, uint32 currentDelay, uint32 pendingDelay, uint48 effect)
    {
        (since, currentDelay, pendingDelay, effect) = roleId._getAccess(account);
    }

    /// @inheritdoc IAccessManager
    function hasRole(uint64 roleId, address account)
        public
        view
        virtual
        returns (bool isMember, uint32 executionDelay)
    {
        if (roleId == PUBLIC_ROLE) {
            return (true, 0);
        } else {
            (uint48 hasRoleSince, uint32 currentDelay,,) = getAccess(roleId, account);
            return (hasRoleSince != 0 && hasRoleSince <= Time.timestamp(), currentDelay);
        }
    }

    // =============================================== ROLE MANAGEMENT ===============================================
    /// @inheritdoc IAccessManager
    function labelRole(uint64 roleId, string calldata label) public virtual onlyAuthorized {
        roleId._labelRole(label);
    }

    /// @inheritdoc IAccessManager
    function grantRole(uint64 roleId, address account, uint32 executionDelay) public virtual onlyAuthorized {
        _grantRole(roleId, account, getRoleGrantDelay(roleId), executionDelay);
    }

    /// @inheritdoc IAccessManager
    function revokeRole(uint64 roleId, address account) public virtual onlyAuthorized {
        _revokeRole(roleId, account);
    }

    /// @inheritdoc IAccessManager
    function renounceRole(uint64 roleId, address callerConfirmation) public virtual {
        roleId._renounceRole(callerConfirmation);
    }

    /// @inheritdoc IAccessManager
    function setRoleAdmin(uint64 roleId, uint64 admin) public virtual onlyAuthorized {
        _setRoleAdmin(roleId, admin);
    }

    /// @inheritdoc IAccessManager
    function setRoleGuardian(uint64 roleId, uint64 guardian) public virtual onlyAuthorized {
        _setRoleGuardian(roleId, guardian);
    }

    /// @inheritdoc IAccessManager
    function setGrantDelay(uint64 roleId, uint32 newDelay) public virtual onlyAuthorized {
        _setGrantDelay(roleId, newDelay);
    }

    /**
     * @dev Internal version of {grantRole} without access control. Returns true if the role was newly granted.
     *
     * Emits a {RoleGranted} event.
     */
    function _grantRole(uint64 roleId, address account, uint32 grantDelay, uint32 executionDelay)
        internal
        virtual
        returns (bool)
    {
        return roleId._grantRole(account, grantDelay, executionDelay);
    }

    /**
     * @dev Internal version of {revokeRole} without access control. This logic is also used by {renounceRole}.
     * Returns true if the role was previously granted.
     *
     * Emits a {RoleRevoked} event if the account had the role.
     */
    function _revokeRole(uint64 roleId, address account) internal virtual returns (bool) {
        return roleId._revokeRole(account);
    }

    /**
     * @dev Internal version of {setRoleAdmin} without access control.
     *
     * Emits a {RoleAdminChanged} event.
     *
     * NOTE: Setting the admin role as the `PUBLIC_ROLE` is allowed, but it will effectively allow
     * anyone to set grant or revoke such role.
     */
    function _setRoleAdmin(uint64 roleId, uint64 admin) internal virtual {
        roleId._setRoleAdmin(admin);
    }

    /**
     * @dev Internal version of {setRoleGuardian} without access control.
     *
     * Emits a {RoleGuardianChanged} event.
     *
     * NOTE: Setting the guardian role as the `PUBLIC_ROLE` is allowed, but it will effectively allow
     * anyone to cancel any scheduled operation for such role.
     */
    function _setRoleGuardian(uint64 roleId, uint64 guardian) internal virtual {
        roleId._setRoleGuardian(guardian);
    }

    /**
     * @dev Internal version of {setGrantDelay} without access control.
     *
     * Emits a {RoleGrantDelayChanged} event.
     */
    function _setGrantDelay(uint64 roleId, uint32 newDelay) internal virtual {
        roleId._setGrantDelay(newDelay);
    }

    // ============================================= FUNCTION MANAGEMENT ==============================================
    /// @inheritdoc IAccessManager
    function setTargetFunctionRole(address target, bytes4[] calldata selectors, uint64 roleId)
        public
        virtual
        onlyAuthorized
    {
        uint256 selectorsLength = selectors.length;
        for (uint256 i; i < selectorsLength; ++i) {
            _setTargetFunctionRole(target, selectors[i], roleId);
        }
    }

    /**
     * @dev Internal version of {setTargetFunctionRole} without access control.
     *
     * Emits a {TargetFunctionRoleUpdated} event.
     */
    function _setTargetFunctionRole(address target, bytes4 selector, uint64 roleId) internal virtual {
        target._setTargetFunctionRole(selector, roleId);
    }

    /// @inheritdoc IAccessManager
    function setTargetAdminDelay(address target, uint32 newDelay) public virtual onlyAuthorized {
        _setTargetAdminDelay(target, newDelay);
    }

    /**
     * @dev Internal version of {setTargetAdminDelay} without access control.
     *
     * Emits a {TargetAdminDelayUpdated} event.
     */
    function _setTargetAdminDelay(address target, uint32 newDelay) internal virtual {
        target._setTargetAdminDelay(newDelay);
    }

    // =============================================== MODE MANAGEMENT ================================================
    /// @inheritdoc IAccessManager
    function setTargetClosed(address target, bool closed) public virtual onlyAuthorized {
        _setTargetClosed(target, closed);
    }

    /**
     * @dev Set the closed flag for a contract. This is an internal setter with no access restrictions.
     *
     * Emits a {TargetClosed} event.
     */
    function _setTargetClosed(address target, bool closed) internal virtual {
        target._setTargetClosed(closed);
    }

    // ============================================== DELAYED OPERATIONS ==============================================
    /// @inheritdoc IAccessManager
    function getSchedule(bytes32 id) public view virtual returns (uint48) {
        return id._getSchedule();
    }

    /// @inheritdoc IAccessManager
    function getNonce(bytes32 id) public view virtual returns (uint32) {
        return id._getNonce();
    }

    /// @inheritdoc IAccessManager
    function schedule(address target, bytes calldata data, uint48 when)
        public
        virtual
        returns (bytes32 operationId, uint32 nonce)
    {
        (operationId, nonce) = target._schedule(data, when);
    }

    /// @inheritdoc IAccessManager
    // Reentrancy is not an issue because permissions are checked on msg.sender. Additionally,
    // _consumeScheduledOp guarantees a scheduled operation is only executed once.
    // slither-disable-next-line reentrancy-no-eth
    function execute(address target, bytes calldata data) public payable virtual returns (uint32) {
        return target._execute(data);
    }

    /// @inheritdoc IAccessManager
    function cancel(address caller, address target, bytes calldata data) public virtual returns (uint32) {
        return caller._cancel(target, data);
    }

    /// @inheritdoc IAccessManager
    function consumeScheduledOp(address caller, bytes calldata data) public virtual {
        address target = _msgSender();
        if (IAccessManaged(target).isConsumingScheduledOp() != IAccessManaged.isConsumingScheduledOp.selector) {
            revert AccessManagerUnauthorizedConsume(target);
        }
        _consumeScheduledOp(hashOperation(caller, target, data));
    }

    /**
     * @dev Internal variant of {consumeScheduledOp} that operates on bytes32 operationId.
     *
     * Returns the nonce of the scheduled operation that is consumed.
     */
    function _consumeScheduledOp(bytes32 operationId) internal virtual returns (uint32) {
        return operationId._consumeScheduledOp();
    }

    /// @inheritdoc IAccessManager
    function hashOperation(address caller, address target, bytes calldata data) public view virtual returns (bytes32) {
        return caller._hashOperation(target, data);
    }

    // ==================================================== OTHERS ====================================================
    /// @inheritdoc IAccessManager
    function updateAuthority(address target, address newAuthority) public virtual onlyAuthorized {
        target._updateAuthority(newAuthority);
    }

    // ================================================= ADMIN LOGIC ==================================================
    /**
     * @dev Check if the current call is authorized according to admin and roles logic.
     *
     * WARNING: Carefully review the considerations of {AccessManaged-restricted} since they apply to this modifier.
     */
    function _checkAuthorized() private {
        LibAccessManager._checkAuthorized();
    }
}
