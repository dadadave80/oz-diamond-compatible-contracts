// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAccessControl} from "@diamond/access/libraries/LibAccessControl.sol";
import {AccessControlImpl} from "@diamond/implementations/access/AccessControlImpl.sol";

contract AccessControlMock is AccessControlImpl {
    function init(address admin) public override reinitializer(_getInitializedVersion() + 1) {
        __AccessControl_init(admin);
        LibAccessControl._registerInterface();
    }

    // for testing
    function _internal_setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        _setRoleAdmin(role, adminRole);
    }

    function _internal_checkRole(bytes32 role) external view {
        _checkRole(role);
    }

    function _internal_grantRole(bytes32 role, address account) external returns (bool) {
        return _grantRole(role, account);
    }

    function _internal_revokeRole(bytes32 role, address account) external returns (bool) {
        return _revokeRole(role, account);
    }
}
