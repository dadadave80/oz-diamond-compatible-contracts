// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant OWNABLE_STORAGE_SLOT = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

/// @custom:storage-location erc7201:openzeppelin.storage.Ownable
struct OwnableStorage {
    address owner;
}
