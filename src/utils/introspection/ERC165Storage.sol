// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC165")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ERC165_STORAGE_SLOT = 0xe7dc48d77ce5afd9f52461d54a45a9e95c3647536a22b51f121b0f857d4a2c00;

/// @custom:storage-location erc7201:openzeppelin.storage.ERC165
struct ERC165Storage {
    mapping(bytes4 interfaceId => bool) supportedInterfaces;
}
