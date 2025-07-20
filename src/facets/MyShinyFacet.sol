// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibShinyDiamond} from "@diamond/libraries/LibShinyDiamond.sol";

contract MyShinyFacet {
    function setShine(uint8 _shine) external {
        LibShinyDiamond._shinyStorage().shineMeter = _shine;
    }

    function getShine() external view returns (uint8) {
        return LibShinyDiamond._shinyStorage().shineMeter;
    }
}
