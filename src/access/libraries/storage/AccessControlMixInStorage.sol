// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlMixin")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_CONTROL_MIXIN_STORAGE_SLOT = 0xb4f1e0b5ab30b2595971826b2838c5da027a01a2afb4597c11cd3a0530e9cd00;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControlMixin
struct AccessControlMixinStorage {
    uint256[10] __gap; // gap for newbie tech debt
    mapping(bytes32 role => RoleData) roles;
    // pending admin pair read/written together frequently
    address pendingDefaultAdmin;
    uint48 pendingDefaultAdminSchedule; // 0 == unset
    uint48 currentDelay;
    address currentDefaultAdmin;
    // pending delay pair read/written together frequently
    uint48 pendingDelay;
    uint48 pendingDelaySchedule; // 0 == unset
}

struct RoleData {
    bytes32 adminRole;
    EnumerableSet.AddressSet roleMembers;
}
