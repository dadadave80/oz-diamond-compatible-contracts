// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {MockDiamond} from "@diamond-test/mocks/diamond/MockDiamond.sol";
import {DiamondCutFacet} from "@diamond/implementations/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/implementations/DiamondLoupeFacet.sol";
import {OwnableImpl} from "@diamond/implementations/access/OwnableImpl.sol";

import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";
import {ERC165Init} from "@diamond/initializers/ERC165Init.sol";

import {FacetCut, FacetCutAction} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {Script} from "forge-std/Script.sol";

/// @title DeployDiamond
/// @notice Deployment script for an EIP-2535 Diamond proxy contract with core facets and ERC165 initialization
/// @author David Dada
contract DeployDiamond is Script, GetSelectors {
    /// @notice Executes the deployment of the Diamond contract with the initial facets and ERC165 interface setup
    /// @dev Broadcasts transactions using Foundry's scripting environment (`vm.startBroadcast()` and `vm.stopBroadcast()`).
    ///      Deploys three core facets, sets up DiamondArgs, encodes an initializer call, and constructs the Diamond.
    /// @return diamond_ The address of the deployed Diamond proxy contract
    function run() external returns (address diamond_, address diamondInit_) {
        vm.startBroadcast();

        // Deploy core facet contracts
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnableImpl ownable = new OwnableImpl();

        // Deploy ERC165 initializer contract
        ERC165Init erc165Init = new ERC165Init();

        diamondInit_ = address(new DiamondInit());

        // Create an array of FacetCut entries for standard facets
        FacetCut[] memory cut = new FacetCut[](3);

        // Add DiamondCutFacet to the cut list
        cut[0] = FacetCut({
            facetAddress: address(diamondCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondCutFacet")
        });

        // Add DiamondLoupeFacet to the cut list
        cut[1] = FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("DiamondLoupeFacet")
        });

        cut[2] = FacetCut({
            facetAddress: address(ownable),
            action: FacetCutAction.Add,
            functionSelectors: _getSelectors("OwnableImpl")
        });

        address[] memory addresses = new address[](2);
        addresses[0] = address(erc165Init);
        addresses[1] = address(ownable);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("registerInterfaces()");
        data[1] = abi.encodeWithSignature("init(address)", LibContext._msgSender());

        // Deploy the Diamond contract with the facets and initialization args
        MockDiamond diamond =
            new MockDiamond(cut, diamondInit_, abi.encodeWithSignature("init(address[],bytes[])", addresses, data));
        diamond_ = address(diamond);

        vm.stopBroadcast();
    }
}
