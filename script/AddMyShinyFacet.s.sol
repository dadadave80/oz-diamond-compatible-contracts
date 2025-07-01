// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {DeployedDiamondState} from "@diamond-test/helpers/TestStates.sol";
import {MyShinyFacet} from "@diamond/facets/MyShinyFacet.sol";
import {FacetCutAction, FacetCut} from "@diamond/libraries/types/DiamondTypes.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";

contract AddMyShinyFacet is Script, DeployedDiamondState {
    MyShinyFacet myShinyFacet;

    function run() external {
        vm.startBroadcast();

        // Deploy MyShinyFacet contract
        myShinyFacet = new MyShinyFacet();

        // Create the array for FacetCuts
        FacetCut[] memory cut = new FacetCut[](1);

        // Add MyShinyFacet address to the array with the action and generate it's selectors
        cut[0] = FacetCut({
            facetAddress: address(myShinyFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("MyShinyFacet")
        });

        // Call diamondCut on the diamond address
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopBroadcast();
    }
}
