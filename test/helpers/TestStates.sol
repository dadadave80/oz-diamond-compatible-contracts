// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {DeployDiamond} from "@diamond-script/DeployDiamond.s.sol";
import {DeployDiamondHelper} from "@diamond-test/helpers/DeployDiamondHelper.sol";
import {Diamond} from "@diamond/Diamond.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";

/// @notice Provides shared state for tests involving a freshly deployed Diamond contract.
/// @dev Sets up references to deployed facets, interfaces, and the diamond itself for testing.
abstract contract DeployedDiamondState is DeployDiamondHelper {
    /// @notice Instance of the deployed Diamond contract.
    Diamond public diamond;

    /// @notice Interface for the DiamondCut functionality of the deployed diamond.
    IDiamondCut public diamondCut;

    /// @notice Interface for the DiamondLoupe functionality of the deployed diamond.
    IDiamondLoupe public diamondLoupe;

    /// @notice Stores the facet addresses returned from the diamond loupe.
    address[] public facetAddresses;

    /// @notice List of facet contract names used in deployment.
    string[3] public facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnableRolesFacet"];

    /// @notice Deploys the Diamond contract and initializes interface references and facet addresses.
    /// @dev This function is intended to be called in a test setup phase (e.g., `setUp()` in Foundry).
    function setUp() public {
        diamond = _deployDiamond(diamondOwner);

        diamondCut = IDiamondCut(address(diamond));
        diamondLoupe = IDiamondLoupe(address(diamond));

        facetAddresses = diamondLoupe.facetAddresses();
    }
}
