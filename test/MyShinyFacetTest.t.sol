// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console} from "forge-std/Test.sol";
import {MyShinyFacet} from "@diamond/facets/MyShinyFacet.sol";
import {AddMyShinyFacetState} from "./helpers/TestStates.sol";

contract MyShinyFacetTest is AddMyShinyFacetState {
    function testSetAndGetShine() public {
        MyShinyFacet(address(diamond)).setShine(50);
        assertEq(MyShinyFacet(address(diamond)).getShine(), 50);
    }
}
