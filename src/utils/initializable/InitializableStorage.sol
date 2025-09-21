// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant INITIALIZABLE_STORAGE_SLOT = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

/// @custom:storage-location erc7201:openzeppelin.storage.Initializable
struct InitializableStorage {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint64 initialized;
    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool initializing;
}
