// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2StepMock} from "@diamond-test/mocks/access/Ownable2StepMock.sol";
import {DiamondBase} from "@diamond-test/states/DiamondBase.sol";
import {OwnershipTransferStarted} from "@diamond/access/Ownable2StepUpgradeable.sol";
import {OwnableUnauthorizedAccount, OwnershipTransferred} from "@diamond/access/libraries/LibOwnable.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {FacetCut, FacetCutAction} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";

contract Ownable2StepImplTest is DiamondBase {
    Ownable2StepMock public ownable2Step;

    function setUp() public override {
        super.setUp();

        ownable2Step = new Ownable2StepMock();

        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = FacetCut({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: _getSelectors("OwnableImpl")
        });

        cut[1] = FacetCut({
            facetAddress: address(ownable2Step),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("Ownable2StepMock")
        });

        diamondCut.diamondCut(cut, address(0), "");

        ownable2Step = Ownable2StepMock(diamond);
    }

    function test_transferOwnershipDoesNotChangeOwner() public {
        vm.expectEmit(diamond);
        emit OwnershipTransferStarted(owner, alice);
        ownable2Step.transferOwnership(alice);

        assertEq(ownable2Step.owner(), owner);
        assertEq(ownable2Step.pendingOwner(), alice);
    }

    function test_acceptOwnership() public {
        ownable2Step.transferOwnership(alice);
        vm.prank(alice);
        vm.expectEmit(diamond);
        emit OwnershipTransferred(owner, alice);
        ownable2Step.acceptOwnership();

        assertEq(ownable2Step.owner(), alice);
        assertEq(ownable2Step.pendingOwner(), address(0));
    }

    function testRevert_acceptOwnership() public {
        ownable2Step.transferOwnership(alice);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, bob));
        ownable2Step.acceptOwnership();
    }

    function test_renounceOwnership() public {
        vm.expectEmit(diamond);
        emit OwnershipTransferred(owner, address(0));
        ownable2Step.renounceOwnership();
    }

    function testRevert_renounceOwnershipByNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, alice));
        ownable2Step.renounceOwnership();
    }

    function test_pendingOwnerResetsAfterRenounceOwnership() public {
        ownable2Step.transferOwnership(alice);
        assertEq(ownable2Step.pendingOwner(), alice);
        ownable2Step.renounceOwnership();
        assertEq(ownable2Step.pendingOwner(), address(0));
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, alice));
        ownable2Step.acceptOwnership();
    }

    function test_cancelOwnershipTransfer() public {
        ownable2Step.transferOwnership(alice);
        assertEq(ownable2Step.pendingOwner(), alice);
        ownable2Step.transferOwnership(address(0));
        assertEq(ownable2Step.pendingOwner(), address(0));
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, alice));
        ownable2Step.acceptOwnership();
    }

    function test_internal_transferOwnership() public {
        ownable2Step.renounceOwnership();
        vm.expectEmit(diamond);
        emit OwnershipTransferred(address(0), bob);
        ownable2Step._internal_transferOwnership(bob);
        assertEq(ownable2Step.owner(), bob);
    }
}
