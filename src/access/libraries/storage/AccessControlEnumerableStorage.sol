// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlEnumerable")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant ACCESS_CONTROL_ENUMERABLE_STORAGE_SLOT =
    0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000;

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControlEnumerable
struct AccessControlEnumerableStorage {
    mapping(bytes32 role => EnumerableSet.AddressSet) roleMembers;
}
