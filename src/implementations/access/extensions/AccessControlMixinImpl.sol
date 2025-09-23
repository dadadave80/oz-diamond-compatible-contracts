// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlDefaultAdminRulesUpgradeable,
    IAccessControl
} from "@diamond/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {
    AccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
} from "@diamond/access/extensions/AccessControlEnumerableUpgradeable.sol";

/*
  ⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⡖
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣤⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⢀⣤⡀
  ⠉⠉⠉⠉⠉⠉⢉⣩⣭⣭⠉⠀⠀⠀⠀⠀⠀⠀⢠⣾⡿⠛⠛⠛⠛⢿⣷⣄⠀⣀⣀⠀⣀⣀⡀⠀⠀⠀⠀⠀⣀⣀⡀⠀⠀⢀⣀⠀⢀⣀⡀⠀⠀⠛⠛⠛⠛⢻⣿⡿⠁⠀⠀⢀⣀⣀⠀⠀⠀⣀⣀⠀⣀⣀⡀⠀⠀⢀⣀⠀⢀⣀⣀⠀⠀⠀⠀⠀⢀⣀⣀⠀⠀⠀⣿⣿⠈⠛⠁⢀⣀⠀⢀⣀⡀
  ⠀⠀⠀⠀⠀⣼⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⠀⣿⣿⡾⠿⠿⣿⣦⡀⠀⣴⡿⠟⠛⢿⣷⡀⢸⣿⣷⠿⢿⣿⣆⠀⠀⠀⠀⣴⣿⠏⠀⠀⢀⣶⡿⠛⠻⢿⣦⠀⣿⣿⡾⠿⠿⣿⣦⡀⢸⣿⣷⠿⠿⢿⣷⣄⠀⢠⣾⠿⠛⠻⣷⣆⠀⣿⣿⢸⣿⡇⢸⣿⣷⠿⢿⣿⣆
  ⠀⠀⠀⠀⣼⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⠀⣿⣿⠀⠀⠀⢸⣿⡇⢸⣿⣷⣶⣶⣶⣿⡷⢸⣿⡇⠀⠀⣿⣿⠀⠀⢠⣾⡿⠁⠀⠀⠀⣾⣿⣶⣶⣶⣾⣿⡇⣿⣿⠀⠀⠀⢸⣿⡇⢸⣿⡇⠀⠀⠀⣿⣿⠀⣿⣿⣶⣶⣶⣾⣿⠀⣿⣿⢸⣿⡇⢸⣿⡇⠀⠀⣿⣿
  ⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⣤⣀⣀⣤⣾⡿⠋⠀⣿⣿⣆⣀⣀⣼⣿⠇⠘⣿⣇⣀⢀⣀⣤⡄⢸⣿⡇⠀⠀⣿⣿⠀⣴⣿⣏⣀⣀⣀⣀⡀⠹⣿⣄⡀⢀⣠⣤⠄⣿⣿⣧⣀⣀⣼⣿⠇⢸⣿⣧⣀⣀⣠⣿⡿⠀⢻⣿⣀⠀⣀⣠⣤⠀⣿⣿⢸⣿⡇⢸⣿⡇⠀⠀⣿⣿
  ⠀⢀⣿⣿⣿⡿⢃⣴⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠙⠻⠿⠿⠟⠋⠀⠀⠀⣿⣿⠙⠻⠿⠛⠁⠀⠀⠈⠛⠿⠿⠛⠋⠀⠘⠛⠃⠀⠀⠛⠛⠀⠛⠛⠛⠛⠛⠛⠛⠃⠀⠈⠛⠿⠿⠛⠁⠀⣿⣿⠙⠻⠿⠛⠁⠀⢸⣿⡏⠛⠿⠟⠋⠀⠀⠀⠙⠻⠿⠟⠛⠁⠀⠛⠛⠘⠛⠃⠘⠛⠃⠀⠀⠛⠛
  ⢠⣿⣿⣿⡟⢡⣾⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⢸⣿⡇
*/

contract AccessControlMixinImpl is AccessControlDefaultAdminRulesUpgradeable, AccessControlEnumerableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function init(uint48 delay, address admin) public virtual initializer {
        __AccessControlDefaultAdminRules_init(delay, admin);
        __AccessControlEnumerable_init(admin);
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, AccessControlDefaultAdminRulesUpgradeable, IAccessControl)
    {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, AccessControlDefaultAdminRulesUpgradeable, IAccessControl)
    {
        super.revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, AccessControlDefaultAdminRulesUpgradeable, IAccessControl)
    {
        super.renounceRole(role, account);
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override(AccessControlEnumerableUpgradeable, AccessControlDefaultAdminRulesUpgradeable)
        returns (bool granted)
    {
        granted = AccessControlDefaultAdminRulesUpgradeable._grantRole(role, account);
        if (granted) {
            AccessControlEnumerableUpgradeable._addRoleMember(role, account);
        }
    }

    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override(AccessControlEnumerableUpgradeable, AccessControlDefaultAdminRulesUpgradeable)
        returns (bool revoked)
    {
        revoked = AccessControlDefaultAdminRulesUpgradeable._revokeRole(role, account);
        if (revoked) {
            AccessControlEnumerableUpgradeable._removeRoleMember(role, account);
        }
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole)
        internal
        virtual
        override(AccessControlUpgradeable, AccessControlDefaultAdminRulesUpgradeable)
    {
        super._setRoleAdmin(role, adminRole);
    }

    /// to resolve override conflicts, it's not used in facets
    function _supportsInterface(bytes4 interfaceId)
        internal
        view
        virtual
        override(AccessControlEnumerableUpgradeable, AccessControlDefaultAdminRulesUpgradeable)
        returns (bool)
    {
        return super._supportsInterface(interfaceId);
    }
}
