// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlDefaultAdminRules")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_CONTROL_DEFAULT_ADMIN_RULES_STORAGE_SLOT =
    0xeef3dac4538c82c8ace4063ab0acd2d15cdb5883aa1dff7c2673abb3d8698400;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControlDefaultAdminRules
struct AccessControlDefaultAdminRulesStorage {
    // pending admin pair read/written together frequently
    address pendingDefaultAdmin;
    uint48 pendingDefaultAdminSchedule; // 0 == unset
    uint48 currentDelay;
    // use ownable's owner slot
    // address currentDefaultAdmin;
    // pending delay pair read/written together frequently
    uint48 pendingDelay;
    uint48 pendingDelaySchedule; // 0 == unset
}
