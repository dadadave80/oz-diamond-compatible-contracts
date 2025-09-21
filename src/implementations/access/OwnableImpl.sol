// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@diamond/access/OwnableUpgradeable.sol";

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

/// @custom:storage-location erc7201:openzeppelin.storage.Ownable
/// @dev keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
contract OwnableImpl is OwnableUpgradeable {
    //layout at 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300 {
    constructor() {
        _disableInitializers();
    }

    function init(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }
}
