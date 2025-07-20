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
import {DeployDiamondHelper} from "@diamond-test/helpers/DeployDiamondHelper.sol";

/// @title DeployDiamond
/// @notice Deployment script for an EIP-2535 Diamond proxy contract with core facets and ERC165 initialization
/// @author David Dada
///
/// @dev Uses Foundry's `Script` and a helper contract to deploy and wire up DiamondCutFacet, DiamondLoupeFacet, and OwnableRolesFacet
contract DeployDiamond is Script, DeployDiamondHelper {
    /// @notice Executes the deployment of the Diamond contract with the initial facets and ERC165 interface setup
    /// @dev Broadcasts transactions using Foundry's scripting environment (`vm.startBroadcast()` and `vm.stopBroadcast()`).
    ///      Deploys three core facets, sets up DiamondArgs, encodes an initializer call, and constructs the Diamond.
    /// @return diamond_ The address of the deployed Diamond proxy contract
    function run() external returns (address diamond_) {
        vm.broadcast();
        diamond_ = _deployDiamond(msg.sender);
    }
}
