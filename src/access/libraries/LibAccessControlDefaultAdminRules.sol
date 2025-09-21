// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAccessControl} from "@diamond/access/libraries/LibAccessControl.sol";
import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";
import {
    ACCESS_CONTROL_DEFAULT_ADMIN_RULES_STORAGE_SLOT,
    AccessControlDefaultAdminRulesStorage,
    DEFAULT_ADMIN_ROLE
} from "@diamond/access/libraries/storage/AccessControlDefaultAdminRulesStorage.sol";
import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {LibERC165} from "@diamond/utils/introspection/LibERC165.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

library LibAccessControlDefaultAdminRules {
    using SafeCast for uint256;

    function _accessControlDefaultAdminRulesStorage()
        internal
        pure
        returns (AccessControlDefaultAdminRulesStorage storage acs_)
    {
        assembly {
            acs_.slot := ACCESS_CONTROL_DEFAULT_ADMIN_RULES_STORAGE_SLOT
        }
    }

    function _registerInterfaces() internal {
        LibERC165._registerInterface(type(IAccessControlDefaultAdminRules).interfaceId);
    }

    function _setRoleAdmin(bytes32 _role, bytes32 _adminRole) internal {
        if (_role == DEFAULT_ADMIN_ROLE) {
            revert IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules();
        }
        LibAccessControl._setRoleAdmin(_role, _adminRole);
    }

    function _grantRole(bytes32 _role, address _account) internal returns (bool) {
        if (_role == DEFAULT_ADMIN_ROLE) {
            if (_defaultAdmin() != address(0)) {
                revert IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules();
            }
            LibOwnable._transferOwnership(_account);
        }
        return LibAccessControl._grantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal returns (bool) {
        if (_role == DEFAULT_ADMIN_ROLE && _account == _defaultAdmin()) {
            LibOwnable._transferOwnership(address(0));
        }
        return LibAccessControl._revokeRole(_role, _account);
    }

    function _renounceRole(bytes32 _role, address _account) internal {
        if (_role == DEFAULT_ADMIN_ROLE && _account == _defaultAdmin()) {
            (address newDefaultAdmin, uint48 schedule) = _pendingDefaultAdmin();
            if (newDefaultAdmin != address(0) || !_isScheduleSet(schedule) || !_hasSchedulePassed(schedule)) {
                revert IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay(schedule);
            }
            delete _accessControlDefaultAdminRulesStorage().pendingDefaultAdminSchedule;
        }
        LibAccessControl._renounceRole(_role, _account);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                   DEFAULT ADMIN / PENDING DEFAULT ADMIN
    //////////////////////////////////////////////////////////////////////////*//

    function _beginDefaultAdminTransfer(address _newAdmin) internal {
        uint48 newSchedule = (block.timestamp + _defaultAdminDelay()).toUint48();
        _setPendingDefaultAdmin(_newAdmin, newSchedule);
        emit IAccessControlDefaultAdminRules.DefaultAdminTransferScheduled(_newAdmin, newSchedule);
    }

    function _cancelDefaultAdminTransfer() internal {
        _setPendingDefaultAdmin(address(0), 0);
    }

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
        AccessControlDefaultAdminRulesStorage storage acs = _accessControlDefaultAdminRulesStorage();
        delete acs.pendingDefaultAdmin;
        delete acs.pendingDefaultAdminSchedule;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //             DEFAULT ADMIN DELAY / PENDING DEFAULT ADMIN DELAY
    //////////////////////////////////////////////////////////////////////////*//

    function _changeDefaultAdminDelay(uint48 _newDelay) internal {
        uint48 newSchedule = (block.timestamp + _delayChangeWait(_newDelay)).toUint48();
        _setPendingDelay(_newDelay, newSchedule);
        emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeScheduled(_newDelay, newSchedule);
    }

    function _rollbackDefaultAdminDelay() internal {
        _setPendingDelay(0, 0);
    }

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

    function _defaultAdmin() internal view returns (address) {
        return LibOwnable._owner();
    }

    function _pendingDefaultAdmin() internal view returns (address newAdmin, uint48 schedule) {
        AccessControlDefaultAdminRulesStorage storage acs = _accessControlDefaultAdminRulesStorage();
        return (acs.pendingDefaultAdmin, acs.pendingDefaultAdminSchedule);
    }

    function _defaultAdminDelay() internal view returns (uint48) {
        AccessControlDefaultAdminRulesStorage storage acs = _accessControlDefaultAdminRulesStorage();
        uint48 schedule = acs.pendingDelaySchedule;
        return (_isScheduleSet(schedule) && _hasSchedulePassed(schedule)) ? acs.pendingDelay : acs.currentDelay;
    }

    function _pendingDefaultAdminDelay() internal view returns (uint48 newDelay, uint48 schedule_) {
        AccessControlDefaultAdminRulesStorage storage acs = _accessControlDefaultAdminRulesStorage();
        schedule_ = acs.pendingDelaySchedule;
        return (_isScheduleSet(schedule_) && !_hasSchedulePassed(schedule_)) ? (acs.pendingDelay, schedule_) : (0, 0);
    }

    function _defaultAdminDelayIncreaseWait() internal pure returns (uint48) {
        return 5 days;
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
        AccessControlDefaultAdminRulesStorage storage acs = _accessControlDefaultAdminRulesStorage();
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
        AccessControlDefaultAdminRulesStorage storage acs = _accessControlDefaultAdminRulesStorage();
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
