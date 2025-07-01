// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @custom:storage-location erc7201:my.shiny.diamond.shiny.storage
struct ShinyStorage {
    uint8 shineMeter;
}

library LibShinyDiamond {
    // keccak256(abi.encode(uint256(keccak256("my.shiny.diamond.shiny.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SHINY_STORAGE_POSITION = 0x88c7da15de62c44228a05e84c85d3e754caab08934817065b4a1faaba4fccf00;

    /// @dev Get the shiny storage.
    function _shinyStorage() internal pure returns (ShinyStorage storage $) {
        bytes32 position = SHINY_STORAGE_POSITION;
        assembly {
            $.slot := position
        }
    }
}
