// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DEFAULT_ADMIN_ROLE, LibAccessControl} from "@diamond/access/libraries/LibAccessControl.sol";
import {LibAccessControlDefaultAdminRules} from "@diamond/access/libraries/LibAccessControlDefaultAdminRules.sol";
import {AccessControlDefaultAdminRulesImpl} from
    "@diamond/implementations/access/extensions/AccessControlDefaultAdminRulesImpl.sol";

contract AccessControlDefaultAdminRulesMock is AccessControlDefaultAdminRulesImpl {
    function init(address admin) public reinitializer(_getInitializedVersion() + 1) {
        LibAccessControl._grantRole(DEFAULT_ADMIN_ROLE, admin);
        LibAccessControlDefaultAdminRules._registerInterfaces();
    }
}
