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
    //layout at 0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000 {
    constructor() {
        _disableInitializers();
    }

    function init(address admin) public virtual initializer {
        __AccessControlEnumerable_init(admin);
    }
}
