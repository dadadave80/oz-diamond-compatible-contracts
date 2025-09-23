// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DiamondBase} from "@diamond-test/states/DiamondBase.sol";
import {
    OwnableInvalidOwner,
    OwnableUnauthorizedAccount,
    OwnershipTransferred
} from "@diamond/access/libraries/LibOwnable.sol";

contract OwnableImplTest is DiamondBase {
    function test_owner() public view {
        assertEq(ownable.owner(), owner);
    }

    function test_transferOwnership() public {
        ownable.transferOwnership(alice);
        assertEq(ownable.owner(), alice);
    }

    function testRevert_transferOwnershipByNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, alice));
        ownable.transferOwnership(bob);
    }

    function testRevert_transferOwnershipToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableInvalidOwner.selector, address(0)));
        ownable.transferOwnership(address(0));
    }

    function test_renounceOwnership() public {
        vm.expectEmit(diamond);
        emit OwnershipTransferred(owner, address(0));
        ownable.renounceOwnership();
    }

    function testRevert_renounceOwnershipByNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, alice));
        ownable.renounceOwnership();
    }
}
