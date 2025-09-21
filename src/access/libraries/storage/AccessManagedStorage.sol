// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessManaged")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_MANAGED_STORAGE_SLOT = 0xf3177357ab46d8af007ab3fdb9af81da189e1068fefdc0073dca88a2cab40a00;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessManaged
struct AccessManagedStorage {
    address authority;
    bool consumingSchedule;
}
