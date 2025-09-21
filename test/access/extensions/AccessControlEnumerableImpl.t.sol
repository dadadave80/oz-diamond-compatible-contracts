// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlEnumerableMock} from "@diamond-test/mocks/access/extensions/AccessControlEnumerableMock.sol";
import {DiamondBase} from "@diamond-test/states/DiamondBase.sol";
import {FacetCut, FacetCutAction} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";

contract AccessControlEnumerableImplTest is DiamondBase {
    AccessControlEnumerableMock public accessControl;
    bytes32 public constant ROLE = keccak256("ROLE");

    function setUp() public override {
        super.setUp();

        accessControl = new AccessControlEnumerableMock();

        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut({
            facetAddress: address(accessControl),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlEnumerableMock")
        });

        diamondCut.diamondCut(cut, address(accessControl), abi.encodeWithSignature("init(address)", owner));

        accessControl = AccessControlEnumerableMock(diamond);
    }

    function test_supportsInterface() public view {
        assertTrue(diamondLoupe.supportsInterface(type(IAccessControlEnumerable).interfaceId));
    }

    function test_enumerateRoleBearers() public {
        accessControl.grantRole(ROLE, alice);
        accessControl.grantRole(ROLE, bob);
        accessControl.grantRole(ROLE, charlie);
        accessControl.revokeRole(ROLE, bob);

        address[2] memory expectedMembers = [alice, charlie];
        uint256 memberCount = accessControl.getRoleMemberCount(ROLE);

        assertEq(memberCount, expectedMembers.length);
        for (uint256 i; i < memberCount; ++i) {
            assertEq(accessControl.getRoleMember(ROLE, i), expectedMembers[i]);
        }
    }

    function test_enumerateRolesAfterRenounce() public {
        assertEq(accessControl.getRoleMemberCount(ROLE), 0);
        accessControl.grantRole(ROLE, owner);
        assertEq(accessControl.getRoleMemberCount(ROLE), 1);
        accessControl.renounceRole(ROLE, owner);
        assertEq(accessControl.getRoleMemberCount(ROLE), 0);
    }
}
