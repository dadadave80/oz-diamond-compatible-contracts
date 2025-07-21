// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {Facet} from "@diamond/libraries/types/DiamondTypes.sol";
import {DeployedDiamondState} from "./helpers/TestStates.sol";

/// @title DiamondTester
/// @notice Contains test cases to validate the deployment and structure of the Diamond contract.
/// @dev Inherits setup and state from DeployedDiamondState to interact with the deployed diamond.
contract DiamondTester is DeployedDiamondState {
    /// @notice Verifies that the diamond contract is successfully deployed.
    function testDiamondDeployed() public view {
        assertNotEq(address(diamond), address(0));
    }

    /// @notice Verifies the diamond owner is set correctly.
    function testDiamondOwner() public view {
        assertEq(ownableRoles.owner(), diamondOwner);
    }

    /// @notice Checks that the standard facets are deployed and have valid addresses.
    /// @dev Expects exactly 3 standard facets: DiamondCut, DiamondLoupe, and OwnableRoles.
    function testStandardFacetsDeployed() public view {
        assertEq(facetAddresses.length, 3);
        for (uint256 i; i < facetAddresses.length; i++) {
            assertNotEq(address(facetAddresses[i]), address(0));
        }
    }

    /// @notice Ensures all function selectors are registered correctly for each facet.
    /// @dev Compares generated selectors with those registered in the diamond via facetAddress().
    function testSelectorsAreComplete() public {
        for (uint256 i; i < facetAddresses.length; i++) {
            bytes4[] memory fromGenSelectors = _generateSelectors(facetNames[i]);
            for (uint256 j; j < fromGenSelectors.length; j++) {
                assertEq(facetAddresses[i], diamondLoupe.facetAddress(fromGenSelectors[j]));
            }
        }
    }

    /// @notice Asserts that all function selectors across all facets are unique.
    function testSelectorsAreUnique() public view {
        bytes4[] memory allSelectors = getAllSelectors(address(diamond));
        for (uint256 i; i < allSelectors.length; i++) {
            for (uint256 j = i + 1; j < allSelectors.length; j++) {
                assertNotEq(allSelectors[i], allSelectors[j]);
            }
        }
    }

    /// @notice Ensures each selector maps back to the correct facet.
    function testSelectorToFacetMappingIsCorrect() public view {
        Facet[] memory facetsList = diamondLoupe.facets();
        for (uint256 i; i < facetsList.length; i++) {
            for (uint256 j; j < facetsList[i].functionSelectors.length; j++) {
                bytes4 selector = facetsList[i].functionSelectors[j];
                address expected = facetsList[i].facetAddress;
                assertEq(diamondLoupe.facetAddress(selector), expected);
            }
        }
    }

    /// @notice Ensures facet addresses return the correct function selectors.
    function testFacetAddressToSelectorsMappingIsCorrect() public view {
        for (uint256 i; i < facetAddresses.length; i++) {
            bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(facetAddresses[i]);
            for (uint256 j; j < selectors.length; j++) {
                assertEq(diamondLoupe.facetAddress(selectors[j]), facetAddresses[i]);
            }
        }
    }

    /// @notice Confirms ERC165 interface support.
    function testSupportsERC165() public view {
        assertTrue(diamondLoupe.supportsInterface(0x01ffc9a7)); // ERC165 interface ID
    }

    /// @notice Confirms ERC173 interface support.
    function testSupportsERC173() public view {
        assertTrue(diamondLoupe.supportsInterface(0x7f5828d0)); // ERC173 interface ID
    }

    /// @notice Confirms IDiamondCut interface support.
    function testSupportsIDiamondCut() public view {
        assertTrue(diamondLoupe.supportsInterface(0x1f931c1c)); // IDiamondCut interface ID
    }

    /// @notice Confirms IDiamondLoupe interface support.
    function testSupportsIDiamondLoupe() public view {
        assertTrue(diamondLoupe.supportsInterface(0x48e2b093)); // IDiamondLoupe interface ID
    }
}
