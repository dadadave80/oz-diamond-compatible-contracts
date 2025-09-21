// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@diamond/access/OwnableUpgradeable.sol";

import {OwnableUnauthorizedAccount} from "@diamond/access/libraries/LibOwnable.sol";
import {LibOwnable2Step} from "@diamond/access/libraries/LibOwnable2Step.sol";
import {ContextUpgradeable} from "@diamond/utils/context/ContextUpgradeable.sol";
import {Initializable} from "@diamond/utils/initializable/Initializable.sol";

event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must call {acceptOwnership} in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable, ContextUpgradeable {
    using LibOwnable2Step for *;

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable2Step_init(address _initialOwner) internal onlyInitializing {
        __Ownable2Step_init_unchained(_initialOwner);
    }

    function __Ownable2Step_init_unchained(address _initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(_initialOwner);
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return LibOwnable2Step._pendingOwner();
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     *
     * Setting `newOwner` to the zero address is allowed; this can be used to cancel an initiated ownership transfer.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        LibOwnable2Step._ownable2StepStorage().pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        LibOwnable2Step._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}
