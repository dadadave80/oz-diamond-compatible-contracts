// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@diamond/access/AccessControlUpgradeable.sol";

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

/// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
/// @dev keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
contract AccessControlImpl is AccessControlUpgradeable {
    //layout at 0x02dD7bC7dEc4DceedDA775e58dD541e08A116C6c53815c0bd028192f7b626800 {
    constructor() {
        _disableInitializers();
    }

    function init(address admin) public virtual initializer {
        __AccessControl_init(admin);
    }
}
