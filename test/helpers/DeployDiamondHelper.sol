// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "@diamond/Diamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {FacetCutAction, FacetCut, DiamondArgs} from "@diamond/libraries/types/DiamondStorage.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";

abstract contract DeployDiamondHelper is HelperContract {
    function _deployDiamond(address _owner) internal returns (address payable diamond_) {
        // Deploy core facet contracts
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnableRolesFacet ownableRolesFacet = new OwnableRolesFacet();

        // Deploy ERC165 initializer contract
        ERC165Init erc165Init = new ERC165Init();

        // Prepare DiamondArgs: owner and init data
        DiamondArgs memory args =
            DiamondArgs({owner: _owner, init: address(erc165Init), initData: abi.encodeWithSignature("initERC165()")});

        // Create an array of FacetCut entries for standard facets
        FacetCut[] memory cut = new FacetCut[](3);

        // Add DiamondCutFacet to the cut list
        cut[0] = FacetCut({
            facetAddress: address(diamondCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondCutFacet")
        });

        // Add DiamondLoupeFacet to the cut list
        cut[1] = FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("DiamondLoupeFacet")
        });

        // Add OwnableRolesFacet to the cut list
        cut[2] = FacetCut({
            facetAddress: address(ownableRolesFacet),
            action: FacetCutAction.Add,
            functionSelectors: _generateSelectors("OwnableRolesFacet")
        });

        // Deploy the Diamond contract with the facets and initialization args
        Diamond diamond = new Diamond(cut, args);
        diamond_ = payable(address(diamond));
    }
}
