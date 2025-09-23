// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlFacetTest,
    DiamondBase,
    FacetCut,
    FacetCutAction
} from "@diamond-test/access/AccessControlFacet.t.sol";

import {AccessControlEnumerableImpl} from "@diamond/implementations/access/extensions/AccessControlEnumerableImpl.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";

contract AccessControlEnumerableMock is AccessControlEnumerableImpl {
    function init(address admin) public virtual override reinitializer(_getInitializedVersion() + 1) {
        __AccessControlEnumerable_init_facet(admin);
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

contract AccessControlEnumerableFacetTest is DiamondBase, AccessControlFacetTest {
    function setUp() public virtual override(AccessControlFacetTest, DiamondBase) {
        DiamondBase.setUp();

        AccessControlEnumerableMock accessControlEnum = new AccessControlEnumerableMock();

        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut({
            facetAddress: address(accessControlEnum),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlEnumerableMock")
        });

        diamondCut.diamondCut(cut, address(accessControlEnum), abi.encodeWithSignature("init(address)", owner));
    }

    function test_supportsInterface() public view virtual override {
        super.test_supportsInterface();
        assertTrue(diamondLoupe.supportsInterface(type(IAccessControlEnumerable).interfaceId));
    }

    function test_enumerateRoleBearers() public {
        AccessControlEnumerableMock(diamond).grantRole(ROLE, alice);
        AccessControlEnumerableMock(diamond).grantRole(ROLE, bob);
        AccessControlEnumerableMock(diamond).grantRole(ROLE, charlie);
        AccessControlEnumerableMock(diamond).revokeRole(ROLE, bob);

        address[2] memory expectedMembers = [alice, charlie];
        uint256 memberCount = AccessControlEnumerableMock(diamond).getRoleMemberCount(ROLE);

        assertEq(memberCount, expectedMembers.length);
        for (uint256 i; i < memberCount; ++i) {
            assertEq(AccessControlEnumerableMock(diamond).getRoleMember(ROLE, i), expectedMembers[i]);
        }
    }

    function test_enumerateRolesAfterRenounce() public {
        assertEq(AccessControlEnumerableMock(diamond).getRoleMemberCount(ROLE), 0);
        AccessControlEnumerableMock(diamond).grantRole(ROLE, owner);
        assertEq(AccessControlEnumerableMock(diamond).getRoleMemberCount(ROLE), 1);
        AccessControlEnumerableMock(diamond).renounceRole(ROLE, owner);
        assertEq(AccessControlEnumerableMock(diamond).getRoleMemberCount(ROLE), 0);
    }
}
