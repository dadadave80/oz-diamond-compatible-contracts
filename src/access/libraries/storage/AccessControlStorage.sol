// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_CONTROL_STORAGE_SLOT = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
struct AccessControlStorage {
    mapping(bytes32 role => RoleData) roles;
}

struct RoleData {
    mapping(address account => bool) hasRole;
    bytes32 adminRole;
}
