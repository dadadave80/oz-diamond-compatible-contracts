// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondBase} from "@diamond-test/states/DiamondBase.sol";
import {DEFAULT_ADMIN_ROLE} from "@diamond/access/libraries/LibAccessControl.sol";
import {AccessControlImpl} from "@diamond/implementations/access/AccessControlImpl.sol";
import {FacetCut, FacetCutAction} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AccessControlMock is AccessControlImpl {
    function init(address admin) public override reinitializer(_getInitializedVersion() + 1) {
        __AccessControl_init_facet(admin);
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

contract AccessControlFacetTest is DiamondBase {
    bytes32 public constant ROLE = keccak256("ROLE");
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");

    function setUp() public virtual override {
        super.setUp();

        AccessControlMock accessControl = new AccessControlMock();

        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut({
            facetAddress: address(accessControl),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlMock")
        });

        diamondCut.diamondCut(cut, address(accessControl), abi.encodeWithSignature("init(address)", owner));
    }

    function test_supportsInterface() public view virtual {
        assertTrue(diamondLoupe.supportsInterface(type(IAccessControl).interfaceId));
    }

    function test_hasDefaultAdminRole() public view {
        assertTrue(AccessControlMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_roleAdminIsDefaultAdminRole() public view {
        assertEq(AccessControlMock(diamond).getRoleAdmin(ROLE), DEFAULT_ADMIN_ROLE);
    }

    function test_defaultAdminRoleAdminIsItself() public view {
        assertEq(AccessControlMock(diamond).getRoleAdmin(DEFAULT_ADMIN_ROLE), DEFAULT_ADMIN_ROLE);
    }

    function test_grantRole() public {
        vm.prank(owner);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, bob, owner);
        AccessControlMock(diamond).grantRole(ROLE, bob);
        assertTrue(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function testRevert_nonAdminCannotGrantRole() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        AccessControlMock(diamond).grantRole(ROLE, bob);
    }

    function test_grantRoleMultipleTimes() public {
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, bob, owner);
        AccessControlMock(diamond).grantRole(ROLE, bob);
        AccessControlMock(diamond).grantRole(ROLE, bob);
        assertTrue(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function test_revokeRole() public {
        AccessControlMock(diamond).grantRole(ROLE, bob);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(ROLE, bob, owner);
        AccessControlMock(diamond).revokeRole(ROLE, bob);
        assertFalse(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function testRevert_nonAdminCannotRevokeRole() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        AccessControlMock(diamond).revokeRole(ROLE, bob);
    }

    function test_revokeRoleMultipleTimes() public {
        AccessControlMock(diamond).grantRole(ROLE, bob);
        AccessControlMock(diamond).revokeRole(ROLE, bob);
        AccessControlMock(diamond).revokeRole(ROLE, bob);
        assertFalse(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function test_renounceRole() public {
        AccessControlMock(diamond).grantRole(ROLE, bob);
        vm.prank(bob);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(ROLE, bob, bob);
        AccessControlMock(diamond).renounceRole(ROLE, bob);
        assertFalse(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function test_nonBearerCanRenounceRole() public {
        vm.prank(alice);
        AccessControlMock(diamond).renounceRole(ROLE, alice);
        assertFalse(AccessControlMock(diamond).hasRole(ROLE, alice));
    }

    function test_renounceRoleMultipleTimes() public {
        AccessControlMock(diamond).grantRole(ROLE, bob);
        vm.prank(bob);
        AccessControlMock(diamond).renounceRole(ROLE, bob);
        vm.prank(bob);
        AccessControlMock(diamond).renounceRole(ROLE, bob);
        assertFalse(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function _internal_setRoleAdmin() public {
        vm.expectEmit(diamond);
        emit IAccessControl.RoleAdminChanged(ROLE, DEFAULT_ADMIN_ROLE, ROLE_ADMIN);
        AccessControlMock(diamond)._internal_setRoleAdmin(ROLE, ROLE_ADMIN);
        AccessControlMock(diamond).grantRole(ROLE_ADMIN, alice);
    }

    function test_getRoleAdmin() public {
        _internal_setRoleAdmin();
        assertEq(AccessControlMock(diamond).getRoleAdmin(ROLE), ROLE_ADMIN);
    }

    function test_newAdminCanGrantRoles() public {
        _internal_setRoleAdmin();
        vm.prank(alice);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, bob, alice);
        AccessControlMock(diamond).grantRole(ROLE, bob);
        assertTrue(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function test_newAdminCanRevokeRoles() public {
        _internal_setRoleAdmin();
        vm.prank(alice);
        AccessControlMock(diamond).grantRole(ROLE, bob);
        vm.prank(alice);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(ROLE, bob, alice);
        AccessControlMock(diamond).revokeRole(ROLE, bob);
        assertFalse(AccessControlMock(diamond).hasRole(ROLE, bob));
    }

    function testRevert_oldAdminCannotGrantRoles() public {
        _internal_setRoleAdmin();
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, owner, ROLE_ADMIN)
        );
        AccessControlMock(diamond).grantRole(ROLE, bob);
    }

    function testRevert_oldAdminCannotRevokeRoles() public {
        _internal_setRoleAdmin();
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, owner, ROLE_ADMIN)
        );
        AccessControlMock(diamond).revokeRole(ROLE, bob);
    }

    function test_checkRole() public {
        AccessControlMock(diamond).grantRole(ROLE, bob);
        vm.prank(bob);
        AccessControlMock(diamond)._internal_checkRole(ROLE);
    }

    function testRevert_nonBearerRole1() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, ROLE));
        AccessControlMock(diamond)._internal_checkRole(ROLE);
    }

    function testRevert_nonBearerRole2() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, ROLE));
        AccessControlMock(diamond)._internal_checkRole(ROLE);
    }

    function test_internal_grantRoleReturnsTrueIfAccountDoesNotHaveRole() public {
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(ROLE, alice, owner);
        assertTrue(AccessControlMock(diamond)._internal_grantRole(ROLE, alice));
    }

    function test_internal_grantRoleReturnsFalseIfAccountHasRole() public {
        AccessControlMock(diamond).grantRole(ROLE, alice);
        assertFalse(AccessControlMock(diamond)._internal_grantRole(ROLE, alice));
    }

    function test_internal_revokeRoleReturnsTrueIfAccountHasRole() public {
        AccessControlMock(diamond).grantRole(ROLE, alice);
        assertTrue(AccessControlMock(diamond)._internal_revokeRole(ROLE, alice));
    }

    function test_internal_revokeRoleReturnsFalseIfAccountDoesNotHaveRole() public {
        assertFalse(AccessControlMock(diamond)._internal_revokeRole(ROLE, alice));
    }
}
