// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

/**
 * @dev The identifier of the admin role. Required to perform most configuration operations including
 * other roles' management and target restrictions.
 */
uint64 constant ADMIN_ROLE = 0; // type(uint64).min

/**
 * @dev The identifier of the public role. Automatically granted to all addresses with no delay.
 */
uint64 constant PUBLIC_ROLE = 18446744073709551615; // type(uint64).max

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessManager")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_MANAGER_STORAGE_SLOT = 0x40c6c8c28789853c7efd823ab20824bbd71718a8a5915e855f6f288c9a26ad00;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessManager
struct AccessManagerStorage {
    mapping(address target => TargetConfig mode) targets;
    mapping(uint64 roleId => Role) roles;
    mapping(bytes32 operationId => Schedule) schedules;
    // Used to identify operations that are currently being executed via {execute}.
    // This should be transient storage when supported by the EVM.
    bytes32 executionId;
}

// Structure that stores the details for a target contract.
struct TargetConfig {
    mapping(bytes4 selector => uint64 roleId) allowedRoles;
    Time.Delay adminDelay;
    bool closed;
}

// Structure that stores the details for a role/account pair. This structures fit into a single slot.
struct Access {
    // Timepoint at which the user gets the permission.
    // If this is either 0 or in the future, then the role permission is not available.
    uint48 since;
    // Delay for execution. Only applies to restricted() / execute() calls.
    Time.Delay delay;
}

// Structure that stores the details of a role.
struct Role {
    // Members of the role.
    mapping(address user => Access access) members;
    // Admin who can grant or revoke permissions.
    uint64 admin;
    // Guardian who can cancel operations targeting functions that need this role.
    uint64 guardian;
    // Delay in which the role takes effect after being granted.
    Time.Delay grantDelay;
}

// Structure that stores the details for a scheduled operation. This structure fits into a single slot.
struct Schedule {
    // Moment at which the operation can be executed.
    uint48 timepoint;
    // Operation nonce to allow third-party contracts to identify the operation.
    uint32 nonce;
}
