// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlDefaultAdminRulesMock,
    DEFAULT_ADMIN_ROLE
} from "@diamond-test/mocks/access/extensions/AccessControlDefaultAdminRulesMock.sol";
import {DiamondBase} from "@diamond-test/states/DiamondBase.sol";
import {FacetCut, FacetCutAction} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

contract AccessControlDefaultAdminRulesImplTest is DiamondBase {
    AccessControlDefaultAdminRulesMock public accessControl;

    function setUp() public override {
        super.setUp();

        accessControl = new AccessControlDefaultAdminRulesMock();

        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = FacetCut({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: _getSelectors("OwnableImpl")
        });

        cut[1] = FacetCut({
            facetAddress: address(accessControl),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlDefaultAdminRulesMock")
        });

        diamondCut.diamondCut(cut, address(accessControl), abi.encodeWithSignature("init(address)", owner));

        accessControl = AccessControlDefaultAdminRulesMock(diamond);
    }

    function test_supportsInterface() public view {
        assertTrue(diamondLoupe.supportsInterface(type(IAccessControlDefaultAdminRules).interfaceId));
    }

    function test_defaultAdmin() public view {
        assertEq(accessControl.defaultAdmin(), owner);
        assertEq(accessControl.owner(), owner);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_defaultAdminTransfer() public {
        accessControl.beginDefaultAdminTransfer(alice);
        vm.warp(block.timestamp + accessControl.defaultAdminDelay() + 1);
        vm.prank(alice);
        accessControl.acceptDefaultAdminTransfer();
        assertEq(accessControl.defaultAdmin(), alice);
        assertEq(accessControl.owner(), alice);
        assertTrue(accessControl.hasRole(DEFAULT_ADMIN_ROLE, alice));
    }

    function test_pendingDefaultAdminReturnsZeroAddressAndZeroScheduleWhenNoTransferScheduled() public view {
        (address newAdmin, uint48 schedule) = accessControl.pendingDefaultAdmin();
        assertEq(newAdmin, address(0));
        assertEq(schedule, 0);
    }

    function test_pendingDefaultAdminReturnsPendingAdminAndScheduleWhenTransferScheduled() public {
        accessControl.beginDefaultAdminTransfer(alice);
        (, uint48 firstSchedule) = accessControl.pendingDefaultAdmin();
        int8[3] memory values = [-1, 0, 1];
        for (uint256 i; i < values.length; ++i) {
            vm.warp(uint256(int256(int48(firstSchedule)) + values[i]));
            (address newAdmin, uint48 schedule) = accessControl.pendingDefaultAdmin();
            assertEq(newAdmin, alice);
            assertEq(schedule, firstSchedule);
        }
    }

    function test_pendingDefaultAdminReturnsZeroAddressAndZeroScheduleWhenTransferAccepted() public {
        accessControl.beginDefaultAdminTransfer(alice);
        (, uint48 firstSchedule) = accessControl.pendingDefaultAdmin();
        vm.warp(firstSchedule + 1);
        vm.prank(alice);
        accessControl.acceptDefaultAdminTransfer();
        (address newAdmin, uint48 schedule) = accessControl.pendingDefaultAdmin();
        assertEq(newAdmin, address(0));
        assertEq(schedule, 0);
    }
}
