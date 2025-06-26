// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {Diamond} from "@diamond/Diamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";
import {FacetCutAction, FacetCut, DiamondArgs} from "@diamond/libraries/types/DiamondTypes.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";

/// @title DeployDiamond
/// @notice Deployment script for an EIP-2535 Diamond proxy contract with core facets and ERC165 initialization
/// @author David Dada
///
/// @dev Uses Foundry's `Script` and a helper contract to deploy and wire up DiamondCutFacet, DiamondLoupeFacet, and OwnableRolesFacet
contract DeployDiamond is Script, HelperContract {
    /// @notice Executes the deployment of the Diamond contract with the initial facets and ERC165 interface setup
    /// @dev Broadcasts transactions using Foundry's scripting environment (`vm.startBroadcast()` and `vm.stopBroadcast()`).
    ///      Deploys three core facets, sets up DiamondArgs, encodes an initializer call, and constructs the Diamond.
    /// @return diamond_ The address of the deployed Diamond proxy contract
    function run() external returns (Diamond diamond_) {
        vm.startBroadcast();

        // Deploy core facet contracts
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnableRolesFacet ownableRolesFacet = new OwnableRolesFacet();

        // Deploy ERC165 initializer contract
        ERC165Init erc165Init = new ERC165Init();

        // Prepare DiamondArgs: owner and init data
        DiamondArgs memory args = DiamondArgs({
            owner: msg.sender,
            init: address(erc165Init),
            initData: abi.encodeWithSignature("initERC165()")
        });

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
        diamond_ = new Diamond(cut, args);

        vm.stopBroadcast();
    }
}
