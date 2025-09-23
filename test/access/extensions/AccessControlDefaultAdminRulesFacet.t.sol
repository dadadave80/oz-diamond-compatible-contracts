// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AccessControlFacetTest,
    DEFAULT_ADMIN_ROLE,
    DiamondBase,
    FacetCut,
    FacetCutAction,
    IAccessControl
} from "@diamond-test/access/AccessControlFacet.t.sol";

import {LibAccessControl} from "@diamond/access/libraries/LibAccessControl.sol";
import {LibAccessControlDefaultAdminRules} from "@diamond/access/libraries/LibAccessControlDefaultAdminRules.sol";
import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";
import {AccessControlDefaultAdminRulesImpl} from
    "@diamond/implementations/access/extensions/AccessControlDefaultAdminRulesImpl.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";

contract AccessControlDefaultAdminRulesMock is AccessControlDefaultAdminRulesImpl {
    function init(uint48 delay, address admin) public override reinitializer(_getInitializedVersion() + 1) {
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

contract AccessControlDefaultAdminRulesFacetTest is DiamondBase, AccessControlFacetTest {
    uint48 constant DELAY = 10 hours;

    function setUp() public virtual override(AccessControlFacetTest, DiamondBase) {
        DiamondBase.setUp();

        AccessControlDefaultAdminRulesMock accessControlDAR = new AccessControlDefaultAdminRulesMock();

        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = FacetCut({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: _getSelectors("OwnableImpl")
        });

        cut[1] = FacetCut({
            facetAddress: address(accessControlDAR),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("AccessControlDefaultAdminRulesMock")
        });

        diamondCut.diamondCut(
            cut, address(accessControlDAR), abi.encodeWithSignature("init(uint48,address)", DELAY, owner)
        );
    }

    function test_supportsInterface() public view virtual override {
        super.test_supportsInterface();
        assertTrue(diamondLoupe.supportsInterface(type(IAccessControlDefaultAdminRules).interfaceId));
    }

    function test_defaultAdmin() public view {
        assertEq(AccessControlDefaultAdminRulesMock(diamond).defaultAdmin(), owner);
        assertEq(AccessControlDefaultAdminRulesMock(diamond).owner(), owner);
        assertEq(
            AccessControlDefaultAdminRulesMock(diamond).defaultAdmin(),
            AccessControlDefaultAdminRulesMock(diamond).owner()
        );
        assertTrue(AccessControlDefaultAdminRulesMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    function test_defaultAdminTransfer() public {
        // Start an admin transfer
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);

        // Wait for the transfer to be accepted
        vm.warp(DELAY + 2);
        vm.prank(alice);
        AccessControlDefaultAdminRulesMock(diamond).acceptDefaultAdminTransfer();

        assertEq(AccessControlDefaultAdminRulesMock(diamond).defaultAdmin(), alice);
        assertEq(AccessControlDefaultAdminRulesMock(diamond).owner(), alice);
        assertTrue(AccessControlDefaultAdminRulesMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, alice));
    }

    function test_pendingDefaultAdminReturnsZeroIfNoPendingDefaultAdminTransfer() public view {
        (address newAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        assertEq(newAdmin, address(0));
        assertEq(schedule, 0);
    }

    function test_pendingDefaultAdminReturnsPendingAdminAndScheduleWhenTransferScheduled() public {
        int8[3] memory fromSchedule = [-1, 0, 1];

        for (uint8 i; i < 3; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);

            // Wait until schedule + fromSchedule
            (, uint48 firstSchedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
            vm.warp(uint256(int256(int48(firstSchedule)) + fromSchedule[i]));

            (address newAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
            assertEq(newAdmin, alice);
            assertEq(schedule, firstSchedule);
        }
    }

    function test_pendingDefaultAdminReturnsZeroAfterSchedulePassesAndTransferAccepted() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);

        // Wait for the transfer to be accepted
        (, uint48 firstSchedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        vm.warp(firstSchedule + 1);

        // Accept the transfer
        vm.prank(alice);
        AccessControlDefaultAdminRulesMock(diamond).acceptDefaultAdminTransfer();

        (address newAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        assertEq(newAdmin, address(0));
        assertEq(schedule, 0);
    }

    function test_defaultAdminDelayIsCorrect() public view {
        assertEq(AccessControlDefaultAdminRulesMock(diamond).defaultAdminDelay(), DELAY);
    }

    function test_defaultAdminDelayReturnsAppropriateValue() public {
        uint48 newDelay = 8080;

        int8[3] memory fromSchedule = [-1, 0, 1];
        bool[3] memory expectNew = [false, false, true];

        for (uint8 i; i < 3; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(newDelay);

            // Wait until schedule + fromSchedule
            (, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
            vm.warp(uint256(int256(int48(schedule)) + fromSchedule[i]));

            uint48 currentDelay = AccessControlDefaultAdminRulesMock(diamond).defaultAdminDelay();
            assertEq(currentDelay, expectNew[i] ? newDelay : DELAY);
        }
    }

    function test_pendingDefaultAdminDelayReturnsZeroIfNotSet() public view {
        (uint48 delay, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
        assertEq(delay, 0);
        assertEq(schedule, 0);
    }

    function test_pendingDefaultAdminDelayReturnsAppropriateValue() public {
        uint48 newDelay = 8080;

        int8[3] memory fromSchedule = [-1, 0, 1];
        uint48[3] memory expectedDelay = [newDelay, newDelay, 0];
        bool[3] memory expectZeroSchedule = [false, false, true];

        for (uint8 i; i < 3; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(newDelay);

            // Wait until schedule + fromSchedule
            (, uint48 firstSchedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
            vm.warp(uint256(int256(int48(firstSchedule) + fromSchedule[i])));

            (uint48 delay, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
            assertEq(delay, expectedDelay[i]);
            assertEq(schedule, expectZeroSchedule[i] ? 0 : firstSchedule);
        }
    }

    function test_defaultAdminDelayIncreaseWaitReturns5Days() public view {
        assertEq(AccessControlDefaultAdminRulesMock(diamond).defaultAdminDelayIncreaseWait(), 5 days);
    }

    function testRevert_grantDefaultAdminRole() public {
        vm.expectRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        AccessControlDefaultAdminRulesMock(diamond).grantRole(DEFAULT_ADMIN_ROLE, alice);
    }

    function testRevert_revokeDefaultAdminRole() public {
        vm.expectRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        AccessControlDefaultAdminRulesMock(diamond).revokeRole(DEFAULT_ADMIN_ROLE, alice);
    }

    function testRevert_cannotChangeDefaultAdminRoleAdmin() public {
        vm.expectRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        AccessControlDefaultAdminRulesMock(diamond)._internal_setRoleAdmin(DEFAULT_ADMIN_ROLE, ROLE);
    }

    function testRevert_cannotGrantDefaultAdminRoleTwice() public {
        vm.expectRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        AccessControlDefaultAdminRulesMock(diamond)._internal_grantRole(DEFAULT_ADMIN_ROLE, alice);
    }

    function testRevert_beginDefaultAdminTransferByNonDefaultAdmin() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, DEFAULT_ADMIN_ROLE)
        );
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(bob);
    }

    function test_setPendingDefaultAdminAndSchedule() public {
        uint256 nextBlockTimestamp = block.timestamp + 1;
        uint48 acceptSchedule = uint48(nextBlockTimestamp) + DELAY;

        vm.warp(nextBlockTimestamp);
        vm.expectEmit(diamond);
        emit IAccessControlDefaultAdminRules.DefaultAdminTransferScheduled(alice, acceptSchedule);
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
        (address pendingAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        assertEq(pendingAdmin, alice);
        assertEq(schedule, acceptSchedule);
    }

    function test_pendingDefaultAdminTransferShouldRestartWhenCalledAgain() public {
        int8[3] memory fromSchedule = [-1, 0, 1];

        for (uint8 i; i < 3; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
            uint256 acceptSchedule = block.timestamp + DELAY;

            // Wait until schedule + fromSchedule
            vm.warp(uint256(int256(acceptSchedule) + fromSchedule[i]));

            // defaultAdmin changes its mind and begin again to another address
            vm.expectEmit(diamond);
            emit IAccessControlDefaultAdminRules.DefaultAdminTransferCanceled();
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(bob);

            uint256 newSchedule = block.timestamp + DELAY;
            (address pendingAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
            assertEq(pendingAdmin, bob);
            assertEq(schedule, newSchedule);
        }
    }

    function test_whenThereIsAPendingDelaychangeDefaultAdminDelayShouldApplyItToNextDefaultAdminTransfer() public {
        int8[3] memory fromSchedule = [-1, 0, 1];
        bool[3] memory expectNewDelay = [false, false, true];
        uint48 newDelay = 3 hours;

        for (uint8 i; i < 3; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(newDelay);
            (, uint48 effectSchedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();

            // Wait until the expected fromSchedule time
            uint256 nextBlockTimestamp = uint256(int256(int48(effectSchedule) + fromSchedule[i]));
            vm.warp(nextBlockTimestamp);

            // Start the new default admin transfer and get its schedule
            uint48 expectedDelay = expectNewDelay[i] ? newDelay : DELAY;
            uint48 expectedAcceptSchedule = uint48(nextBlockTimestamp + expectedDelay);
            vm.expectEmit(diamond);
            emit IAccessControlDefaultAdminRules.DefaultAdminTransferScheduled(alice, expectedAcceptSchedule);
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);

            // Check that the schedule corresponds with the new delay
            (address pendingAdmin, uint48 transferSchedule) =
                AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
            assertEq(pendingAdmin, alice);
            assertEq(transferSchedule, expectedAcceptSchedule);
        }
    }

    function testRevert_acceptAdminTransferByNonPendingAdmin() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
        vm.warp(block.timestamp + DELAY + 1);
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, bob)
        );
        AccessControlDefaultAdminRulesMock(diamond).acceptDefaultAdminTransfer();
    }

    function test_acceptAdminTransferByPendingAdmin() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
        vm.warp(block.timestamp + DELAY + 1);
        vm.prank(alice);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(DEFAULT_ADMIN_ROLE, owner, alice);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(DEFAULT_ADMIN_ROLE, alice, alice);
        AccessControlDefaultAdminRulesMock(diamond).acceptDefaultAdminTransfer();

        // Storage changes
        assertFalse(AccessControlDefaultAdminRulesMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertTrue(AccessControlDefaultAdminRulesMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, alice));
        assertEq(AccessControlDefaultAdminRulesMock(diamond).owner(), alice);

        // Resets pending default admin and schedule
        (address pendingAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        assertEq(pendingAdmin, address(0));
        assertEq(schedule, 0);
    }

    function testRevert_whenScheduleNotPassed() public {
        int8[2] memory fromSchedule = [-1, 0];
        for (uint8 i; i < 2; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
            uint256 acceptSchedule = block.timestamp + DELAY;

            vm.warp(uint256(int256(acceptSchedule) + fromSchedule[i]));
            vm.prank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay.selector, acceptSchedule
                )
            );
            AccessControlDefaultAdminRulesMock(diamond).acceptDefaultAdminTransfer();
        }
    }

    function testRevert_cancelDefaultAdminTransferByNonDefaultAdmin() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, bob, DEFAULT_ADMIN_ROLE)
        );
        AccessControlDefaultAdminRulesMock(diamond).cancelDefaultAdminTransfer();
    }

    function test_cancelDefaultAdminTransfer() public {
        int8[3] memory fromSchedule = [-1, 0, 1];
        for (uint8 i; i < 3; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
            uint256 acceptSchedule = block.timestamp + DELAY;
            // Advance until passed delay
            vm.warp(uint256(int256(acceptSchedule) + fromSchedule[i]));

            vm.expectEmit(diamond);
            emit IAccessControlDefaultAdminRules.DefaultAdminTransferCanceled();
            AccessControlDefaultAdminRulesMock(diamond).cancelDefaultAdminTransfer();

            // Storage changes
            (address pendingAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
            assertEq(pendingAdmin, address(0));
            assertEq(schedule, 0);
        }
    }

    function testRevert_acceptDefaultAdminAfterCancelAndSchedulePassed() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(alice);
        uint256 acceptSchedule = block.timestamp + DELAY;

        AccessControlDefaultAdminRulesMock(diamond).cancelDefaultAdminTransfer();

        // Advance until passed delay
        vm.warp(acceptSchedule + 1);

        // Previous pending default admin should not be able to accept after cancellation
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, alice)
        );
        AccessControlDefaultAdminRulesMock(diamond).acceptDefaultAdminTransfer();
    }

    function test_cancelDefaultAdminPassesWithoutChanges() public {
        AccessControlDefaultAdminRulesMock(diamond).cancelDefaultAdminTransfer();

        (address pendingAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        assertEq(pendingAdmin, address(0));
        assertEq(schedule, 0);
    }

    function testRevert_renounceDefaultAdminByNonDefaultAdmin() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(address(0));

        vm.warp(DELAY + 1);
        vm.expectRevert(IAccessControl.AccessControlBadConfirmation.selector);
        AccessControlDefaultAdminRulesMock(diamond).renounceRole(DEFAULT_ADMIN_ROLE, alice);
    }

    function testRevert_renounceDefaultAdminByNonAdminDoesNotAffectSchedule() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(address(0));
        uint256 expectedSchedule = block.timestamp + DELAY;

        vm.warp(DELAY + 1);
        vm.prank(alice);
        AccessControlDefaultAdminRulesMock(diamond).renounceRole(DEFAULT_ADMIN_ROLE, alice);

        (address pendingAdmin, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdmin();
        assertEq(pendingAdmin, address(0));
        assertEq(schedule, expectedSchedule);
    }

    function test_renounceRoleByNonDefaultAdminHasNoEffect() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(address(0));

        vm.prank(alice);
        AccessControlDefaultAdminRulesMock(diamond).renounceRole(DEFAULT_ADMIN_ROLE, alice);

        assertTrue(AccessControlDefaultAdminRulesMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertEq(AccessControlDefaultAdminRulesMock(diamond).defaultAdmin(), owner);
    }

    function test_renounceDefaultAdminRole() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(address(0));

        vm.warp(DELAY + 2);
        vm.expectEmit(diamond);
        emit IAccessControl.RoleRevoked(DEFAULT_ADMIN_ROLE, owner, owner);
        AccessControlDefaultAdminRulesMock(diamond).renounceRole(DEFAULT_ADMIN_ROLE, owner);

        assertFalse(AccessControlDefaultAdminRulesMock(diamond).hasRole(DEFAULT_ADMIN_ROLE, owner));
        assertEq(AccessControlDefaultAdminRulesMock(diamond).defaultAdmin(), address(0));
        assertEq(AccessControlDefaultAdminRulesMock(diamond).owner(), address(0));
    }

    function test_internal_grantRoleToRecoverDefaultAdminAccess() public {
        AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(address(0));

        vm.warp(DELAY + 2);
        AccessControlDefaultAdminRulesMock(diamond).renounceRole(DEFAULT_ADMIN_ROLE, owner);

        vm.expectEmit(diamond);
        emit IAccessControl.RoleGranted(DEFAULT_ADMIN_ROLE, bob, owner);
        AccessControlDefaultAdminRulesMock(diamond)._internal_grantRole(DEFAULT_ADMIN_ROLE, bob);
    }

    function testRevert_renounceDefaultAdminScheduleNotPassed() public {
        int8[2] memory fromSchedule = [-1, 0];

        for (uint8 i; i < 2; ++i) {
            AccessControlDefaultAdminRulesMock(diamond).beginDefaultAdminTransfer(address(0));
            uint256 expectedSchedule = block.timestamp + DELAY;

            vm.warp(uint256(int256(int48(DELAY) + fromSchedule[i])));
            vm.expectRevert(
                abi.encodeWithSelector(
                    IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay.selector, expectedSchedule
                )
            );
            AccessControlDefaultAdminRulesMock(diamond).renounceRole(DEFAULT_ADMIN_ROLE, owner);
        }
    }

    function testRevert_changeDefaultAdminDelayByNonDefaultAdmin() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, bob, DEFAULT_ADMIN_ROLE)
        );
        AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(5 hours);
    }

    function test_changeDefaultAdminDelayBeginsChangeToNewDelay() public {
        int32 decreased = -1 hours;
        int32 increased = 1 hours;
        int32 increased5Days = 5 days;
        int32[3] memory delayDifference = [decreased, increased, increased5Days];

        for (uint8 i; i < 3; ++i) {
            uint48 newDefaultAdminDelay = uint48(int48(DELAY) + delayDifference[i]);

            // Calculate expected values
            uint48 capWait = AccessControlDefaultAdminRulesMock(diamond).defaultAdminDelayIncreaseWait();
            uint48 minWait = capWait < newDefaultAdminDelay ? capWait : newDefaultAdminDelay;
            uint48 changeDelay = newDefaultAdminDelay <= DELAY ? DELAY - newDefaultAdminDelay : minWait;
            uint48 nextBlockTimestamp = uint48(block.timestamp) + 1;
            uint48 effectSchedule = nextBlockTimestamp + changeDelay;

            vm.warp(nextBlockTimestamp);

            // Begins the change
            vm.expectEmit(diamond);
            emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeScheduled(newDefaultAdminDelay, effectSchedule);
            AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(newDefaultAdminDelay);

            // Assert
            (uint48 newDelay, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
            assertEq(newDelay, newDefaultAdminDelay);
            assertEq(schedule, effectSchedule);
        }
    }

    function test_changeDefaultAdminDelayScheduleAgain() public {
        int48 decreased = -1 hours;
        int48 increased = 1 hours;
        int48 increased5Days = 5 days;
        int48[3] memory delayDifference = [decreased, increased, increased5Days];

        for (uint8 i; i < 3; ++i) {
            uint48 newDefaultAdminDelay = uint48(int48(DELAY) + delayDifference[i]);
            int8[3] memory fromSchedule = [-1, 0, 1];

            for (uint8 j; j < 3; ++j) {
                AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(newDefaultAdminDelay);
                bool passed = fromSchedule[j] > 0;

                // Wait until schedule + fromSchedule
                (, uint48 firstSchedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
                uint48 nextBlockTimestamp = uint48(int48(firstSchedule) + fromSchedule[j]);
                vm.warp(nextBlockTimestamp);

                // Calculate expected values
                uint48 anotherNewDefaultAdminDelay = newDefaultAdminDelay + 2 hours;
                uint48 capWait = AccessControlDefaultAdminRulesMock(diamond).defaultAdminDelayIncreaseWait();
                uint48 minWait = capWait < anotherNewDefaultAdminDelay ? capWait : anotherNewDefaultAdminDelay;
                uint48 effectSchedule = nextBlockTimestamp + minWait;

                // Default admin changes its mind and begins another delay change
                if (!passed) {
                    vm.expectEmit(diamond);
                    emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeCanceled();
                }
                vm.expectEmit(diamond);
                emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeScheduled(
                    anotherNewDefaultAdminDelay, effectSchedule
                );
                AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(anotherNewDefaultAdminDelay);

                // Assert
                (uint48 newDelay, uint48 schedule) =
                    AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
                assertEq(newDelay, anotherNewDefaultAdminDelay);
                assertEq(schedule, effectSchedule);
            }
        }
    }

    function testRevert_rollbackDefaultAdminDelayByNonDefaultAdmin() public {
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, bob, DEFAULT_ADMIN_ROLE)
        );
        AccessControlDefaultAdminRulesMock(diamond).rollbackDefaultAdminDelay();
    }

    function test_rollbackDefaultAdminDelayResetsPendingDelayAndSchedule() public {
        int8[3] memory fromSchedule = [-1, 0, 1];

        for (uint8 i; i < 3; ++i) {
            bool passed = fromSchedule[i] > 0;
            AccessControlDefaultAdminRulesMock(diamond).changeDefaultAdminDelay(12 hours);

            // Wait until schedule + fromSchedule
            (, uint48 firstSchedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
            vm.warp(uint48(int48(firstSchedule) + fromSchedule[i]));

            if (!passed) {
                vm.expectEmit(diamond);
                emit IAccessControlDefaultAdminRules.DefaultAdminDelayChangeCanceled();
            }
            AccessControlDefaultAdminRulesMock(diamond).rollbackDefaultAdminDelay();

            (uint48 newDelay, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
            assertEq(newDelay, 0);
            assertEq(schedule, 0);
        }
    }

    function test_rollbackDefaultAdminDelaySucceedsWithoutChanges() public {
        AccessControlDefaultAdminRulesMock(diamond).rollbackDefaultAdminDelay();

        (uint48 newDelay, uint48 schedule) = AccessControlDefaultAdminRulesMock(diamond).pendingDefaultAdminDelay();
        assertEq(newDelay, 0);
        assertEq(schedule, 0);
    }
}
