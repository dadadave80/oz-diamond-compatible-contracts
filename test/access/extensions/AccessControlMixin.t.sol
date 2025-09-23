// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlFacetTest,
    DEFAULT_ADMIN_ROLE,
    DiamondBase,
    FacetCut,
    FacetCutAction
} from "@diamond-test/access/AccessControlFacet.t.sol";

import {AccessControlDefaultAdminRulesFacetTest} from
    "@diamond-test/access/extensions/AccessControlDefaultAdminRulesFacet.t.sol";
import {AccessControlEnumerableFacetTest} from "@diamond-test/access/extensions/AccessControlEnumerableFacet.t.sol";

import {LibAccessControl} from "@diamond/access/libraries/LibAccessControl.sol";
import {LibAccessControlDefaultAdminRules} from "@diamond/access/libraries/LibAccessControlDefaultAdminRules.sol";
import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";
import {AccessControlMixinImpl} from "@diamond/implementations/access/extensions/AccessControlMixinImpl.sol";

contract AccessControlMixinMock is AccessControlMixinImpl {
    function init(uint48 delay, address admin) public override reinitializer(_getInitializedVersion() + 1) {
        __AccessControlEnumerable_init_facet(admin);
        if (admin == address(0)) {
            revert AccessControlInvalidDefaultAdmin(address(0));
        }
        LibAccessControlDefaultAdminRules._accessControlDefaultAdminRulesStorage().currentDelay = delay;
        LibAccessControl._grantRole(DEFAULT_ADMIN_ROLE, admin);
        LibOwnable._transferOwnership(admin);
        LibAccessControlDefaultAdminRules._registerInterface();
    }

    // for tests
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

contract AccessControlMixinTest is
    DiamondBase,
    AccessControlFacetTest,
    AccessControlEnumerableFacetTest,
    AccessControlDefaultAdminRulesFacetTest
{
    AccessControlMixinMock accessControlMixin;

    function setUp()
        public
        override(
            AccessControlFacetTest, AccessControlEnumerableFacetTest, AccessControlDefaultAdminRulesFacetTest, DiamondBase
        )
    {
        DiamondBase.setUp();

        accessControlMixin = new AccessControlMixinMock();

        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = FacetCut({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: _getSelectors("OwnableImpl")
        });

        cut[1] = FacetCut({
            facetAddress: address(accessControlMixin),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlMixinMock")
        });

        diamondCut.diamondCut(
            cut, address(accessControlMixin), abi.encodeWithSignature("init(uint48,address)", DELAY, owner)
        );

        accessControlMixin = AccessControlMixinMock(diamond);
    }

    function _mock()
        internal
        view
        virtual
        override(AccessControlFacetTest, AccessControlEnumerableFacetTest, AccessControlDefaultAdminRulesFacetTest)
        returns (address)
    {
        return address(accessControlMixin);
    }

    function test_supportsInterface()
        public
        view
        override(AccessControlFacetTest, AccessControlEnumerableFacetTest, AccessControlDefaultAdminRulesFacetTest)
    {
        super.test_supportsInterface();
    }
}
