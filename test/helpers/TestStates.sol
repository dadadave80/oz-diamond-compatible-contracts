// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {DeployDiamondHelper} from "@diamond-test/helpers/DeployDiamondHelper.sol";
import {Diamond} from "@diamond/Diamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";

/// @notice Provides shared state for tests involving a freshly deployed Diamond contract.
/// @dev Sets up references to deployed facets, interfaces, and the diamond itself for testing.
abstract contract DeployedDiamondState is DeployDiamondHelper {
    /// @notice Instance of the deployed Diamond contract.
    address public diamond;

    /// @notice Interface for the DiamondCut functionality of the deployed diamond.
    DiamondCutFacet public diamondCut;

    /// @notice Interface for the DiamondLoupe functionality of the deployed diamond.
    DiamondLoupeFacet public diamondLoupe;

    /// @notice Interface for the OwnableRoles functionality of the deployed diamond.
    OwnableRolesFacet public ownableRoles;

    /// @notice Stores the facet addresses returned from the diamond loupe.
    address[] public facetAddresses;

    /// @notice List of facet contract names used in deployment.
    string[3] public facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnableRolesFacet"];

    address public diamondOwner = makeAddr("Owner");

    /// @notice Deploys the Diamond contract and initializes interface references and facet addresses.
    /// @dev This function is intended to be called in a test setup phase (e.g., `setUp()` in Foundry).
    function setUp() public {
        vm.startPrank(diamondOwner);
        diamond = _deployDiamond(diamondOwner);

        diamondCut = DiamondCutFacet(address(diamond));
        diamondLoupe = DiamondLoupeFacet(address(diamond));
        ownableRoles = OwnableRolesFacet(address(diamond));

        facetAddresses = diamondLoupe.facetAddresses();
    }
}
