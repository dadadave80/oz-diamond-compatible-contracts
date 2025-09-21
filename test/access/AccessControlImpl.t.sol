// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlMock} from "@diamond-test/mocks/access/AccessControlMock.sol";
import {DiamondBase} from "@diamond-test/states/DiamondBase.sol";
import {DEFAULT_ADMIN_ROLE} from "@diamond/access/libraries/storage/AccessControlStorage.sol";
import {FacetCut, FacetCutAction} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AccessControlImplTest is DiamondBase {
    AccessControlMock public accessControl;
    bytes32 public constant ROLE = keccak256("ROLE");
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    function setUp() public override {
        super.setUp();

        accessControl = new AccessControlMock();

        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut({
            facetAddress: address(accessControl),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlMock")
        });

        diamondCut.diamondCut(cut, address(accessControl), abi.encodeWithSignature("init(address)", owner));

        accessControl = AccessControlMock(diamond);
    }

    function test_supportsInterface() public view {
        assertTrue(diamondLoupe.supportsInterface(type(IAccessControl).interfaceId));
    }

    function test_hasDefaultAdminRole() public view {
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_roleAdminIsDefaultAdminRole() public view {
        assertEq(accessControl.getRoleAdmin(ROLE), DEFAULT_ADMIN_ROLE);
    }

    function test_defaultAdminRoleAdminIsItself() public view {
        assertEq(accessControl.getRoleAdmin(DEFAULT_ADMIN_ROLE), DEFAULT_ADMIN_ROLE);
    }

    function test_grantRole() public {
        vm.prank(owner);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, bob, owner);
        accessControl.grantRole(ROLE, bob);
        assertTrue(accessControl.hasRole(ROLE, bob));
    }

    function testRevert_nonAdminCannotGrantRole() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        accessControl.grantRole(ROLE, bob);
    }

    function test_grantRoleMultipleTimes() public {
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, bob, owner);
        accessControl.grantRole(ROLE, bob);
        accessControl.grantRole(ROLE, bob);
        assertTrue(accessControl.hasRole(ROLE, bob));
    }

    function test_revokeRole() public {
        accessControl.grantRole(ROLE, bob);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(ROLE, bob, owner);
        accessControl.revokeRole(ROLE, bob);
        assertFalse(accessControl.hasRole(ROLE, bob));
    }

    function testRevert_nonAdminCannotRevokeRole() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        accessControl.revokeRole(ROLE, bob);
    }

    function test_revokeRoleMultipleTimes() public {
        accessControl.grantRole(ROLE, bob);
        accessControl.revokeRole(ROLE, bob);
        accessControl.revokeRole(ROLE, bob);
        assertFalse(accessControl.hasRole(ROLE, bob));
    }

    function test_renounceRole() public {
        accessControl.grantRole(ROLE, bob);
        vm.prank(bob);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(ROLE, bob, bob);
        accessControl.renounceRole(ROLE, bob);
        assertFalse(accessControl.hasRole(ROLE, bob));
    }

    function test_nonBearerCanRenounceRole() public {
        vm.prank(alice);
        accessControl.renounceRole(ROLE, alice);
        assertFalse(accessControl.hasRole(ROLE, alice));
    }

    function test_renounceRoleMultipleTimes() public {
        accessControl.grantRole(ROLE, bob);
        vm.prank(bob);
        accessControl.renounceRole(ROLE, bob);
        vm.prank(bob);
        accessControl.renounceRole(ROLE, bob);
        assertFalse(accessControl.hasRole(ROLE, bob));
    }

    function _internal_setRoleAdmin() public {
        vm.expectEmit(diamond);
        emit IAccessControl.RoleAdminChanged(ROLE, DEFAULT_ADMIN_ROLE, ROLE_ADMIN);
        accessControl._internal_setRoleAdmin(ROLE, ROLE_ADMIN);
        accessControl.grantRole(ROLE_ADMIN, alice);
    }

    function test_getRoleAdmin() public {
        _internal_setRoleAdmin();
        assertEq(accessControl.getRoleAdmin(ROLE), ROLE_ADMIN);
    }

    function test_newAdminCanGrantRoles() public {
        _internal_setRoleAdmin();
        vm.prank(alice);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, bob, alice);
        accessControl.grantRole(ROLE, bob);
        assertTrue(accessControl.hasRole(ROLE, bob));
    }

    function test_newAdminCanRevokeRoles() public {
        _internal_setRoleAdmin();
        vm.prank(alice);
        accessControl.grantRole(ROLE, bob);
        vm.prank(alice);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(ROLE, bob, alice);
        accessControl.revokeRole(ROLE, bob);
        assertFalse(accessControl.hasRole(ROLE, bob));
    }

    function testRevert_oldAdminCannotGrantRoles() public {
        _internal_setRoleAdmin();
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, owner, ROLE_ADMIN)
        );
        accessControl.grantRole(ROLE, bob);
    }

    function testRevert_oldAdminCannotRevokeRoles() public {
        _internal_setRoleAdmin();
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, owner, ROLE_ADMIN)
        );
        accessControl.revokeRole(ROLE, bob);
    }

    function test_checkRole() public {
        accessControl.grantRole(ROLE, bob);
        vm.prank(bob);
        accessControl._internal_checkRole(ROLE);
    }

    function testRevert_nonBearerRole1() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, ROLE));
        accessControl._internal_checkRole(ROLE);
    }

    function testRevert_nonBearerRole2() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, ROLE));
        accessControl._internal_checkRole(ROLE);
    }

    function test_internal_grantRoleReturnsTrueIfAccountDoesNotHaveRole() public {
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, alice, owner);
        assertTrue(accessControl._internal_grantRole(ROLE, alice));
    }

    function test_internal_grantRoleReturnsFalseIfAccountHasRole() public {
        accessControl.grantRole(ROLE, alice);
        assertFalse(accessControl._internal_grantRole(ROLE, alice));
    }

    function test_internal_revokeRoleReturnsTrueIfAccountHasRole() public {
        accessControl.grantRole(ROLE, alice);
        assertTrue(accessControl._internal_revokeRole(ROLE, alice));
    }

    function test_internal_revokeRoleReturnsFalseIfAccountDoesNotHaveRole() public {
        assertFalse(accessControl._internal_revokeRole(ROLE, alice));
    }
}
