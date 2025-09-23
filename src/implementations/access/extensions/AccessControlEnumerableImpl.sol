// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlEnumerableUpgradeable} from "@diamond/access/extensions/AccessControlEnumerableUpgradeable.sol";

/*
  ⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⡖
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣤⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣤⢀⣤⡀
  ⠉⠉⠉⠉⠉⠉⢉⣩⣭⣭⠉⠀⠀⠀⠀⠀⠀⠀⢠⣾⡿⠛⠛⠛⠛⢿⣷⣄⠀⣀⣀⠀⣀⣀⡀⠀⠀⠀⠀⠀⣀⣀⡀⠀⠀⢀⣀⠀⢀⣀⡀⠀⠀⠛⠛⠛⠛⢻⣿⡿⠁⠀⠀⢀⣀⣀⠀⠀⠀⣀⣀⠀⣀⣀⡀⠀⠀⢀⣀⠀⢀⣀⣀⠀⠀⠀⠀⠀⢀⣀⣀⠀⠀⠀⣿⣿⠈⠛⠁⢀⣀⠀⢀⣀⡀
  ⠀⠀⠀⠀⠀⣼⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⠀⣿⣿⡾⠿⠿⣿⣦⡀⠀⣴⡿⠟⠛⢿⣷⡀⢸⣿⣷⠿⢿⣿⣆⠀⠀⠀⠀⣴⣿⠏⠀⠀⢀⣶⡿⠛⠻⢿⣦⠀⣿⣿⡾⠿⠿⣿⣦⡀⢸⣿⣷⠿⠿⢿⣷⣄⠀⢠⣾⠿⠛⠻⣷⣆⠀⣿⣿⢸⣿⡇⢸⣿⣷⠿⢿⣿⣆
  ⠀⠀⠀⠀⣼⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⠀⣿⣿⠀⠀⠀⢸⣿⡇⢸⣿⣷⣶⣶⣶⣿⡷⢸⣿⡇⠀⠀⣿⣿⠀⠀⢠⣾⡿⠁⠀⠀⠀⣾⣿⣶⣶⣶⣾⣿⡇⣿⣿⠀⠀⠀⢸⣿⡇⢸⣿⡇⠀⠀⠀⣿⣿⠀⣿⣿⣶⣶⣶⣾⣿⠀⣿⣿⢸⣿⡇⢸⣿⡇⠀⠀⣿⣿
  ⠀⠀⢀⣾⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⣤⣀⣀⣤⣾⡿⠋⠀⣿⣿⣆⣀⣀⣼⣿⠇⠘⣿⣇⣀⢀⣀⣤⡄⢸⣿⡇⠀⠀⣿⣿⠀⣴⣿⣏⣀⣀⣀⣀⡀⠹⣿⣄⡀⢀⣠⣤⠄⣿⣿⣧⣀⣀⣼⣿⠇⢸⣿⣧⣀⣀⣠⣿⡿⠀⢻⣿⣀⠀⣀⣠⣤⠀⣿⣿⢸⣿⡇⢸⣿⡇⠀⠀⣿⣿
  ⠀⢀⣿⣿⣿⡿⢃⣴⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠙⠻⠿⠿⠟⠋⠀⠀⠀⣿⣿⠙⠻⠿⠛⠁⠀⠀⠈⠛⠿⠿⠛⠋⠀⠘⠛⠃⠀⠀⠛⠛⠀⠛⠛⠛⠛⠛⠛⠛⠃⠀⠈⠛⠿⠿⠛⠁⠀⣿⣿⠙⠻⠿⠛⠁⠀⢸⣿⡏⠛⠿⠟⠋⠀⠀⠀⠙⠻⠿⠟⠛⠁⠀⠛⠛⠘⠛⠃⠘⠛⠃⠀⠀⠛⠛
  ⢠⣿⣿⣿⡟⢡⣾⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⢸⣿⡇
*/

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControlEnumerable
/// @dev keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControlEnumerable")) - 1)) & ~bytes32(uint256(0xff))
contract AccessControlEnumerableImpl is AccessControlEnumerableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function init(address admin) public virtual initializer {
        __AccessControlEnumerable_init(admin);
    }
}
