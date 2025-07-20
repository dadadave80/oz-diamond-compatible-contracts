// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "@diamond/Diamond.sol";
import {FacetCutAction, FacetCut} from "@diamond/libraries/types/DiamondTypes.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {MyShinyFacet} from "@diamond/facets/MyShinyFacet.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";

abstract contract AddMyShinyFacetHelper is HelperContract {
    function _addMyShinyFacet(Diamond diamond) internal returns (MyShinyFacet myShinyFacet_) {
        // Deploy MyShinyFacet contract
        myShinyFacet_ = new MyShinyFacet();

        // Create the array for FacetCuts
        FacetCut[] memory cut = new FacetCut[](1);

        // Add MyShinyFacet address to the array with the action and generate it's selectors
        cut[0] = FacetCut({
            facetAddress: address(myShinyFacet_),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("MyShinyFacet")
        });

        // Call diamondCut on the diamond address
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }
}
