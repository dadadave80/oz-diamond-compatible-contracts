// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {EnumerableSet, Facet} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {DiamondStorage, LibDiamond} from "@diamond/proxy/diamond/libraries/LibDiamond.sol";
import {EnumerableBytes4Set} from "@diamond/utils/EnumerableBytes4Set.sol";
import {LibERC165} from "@diamond/utils/introspection/LibERC165.sol";

/// @notice Provides read-only functions to inspect the state of a Diamond proxy, including facets, function selectors, and supported interfaces
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/facets/DiamondLoupeFacet.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/facets/DiamondLoupeFacet.sol)
///
/// @dev Implements the IDiamondLoupe interface as defined in EIP-2535
contract DiamondLoupeFacet is IDiamondLoupe {
    using EnumerableBytes4Set for EnumerableBytes4Set.Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Gets all facet addresses and their function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_) {
        DiamondStorage storage ds = LibDiamond._diamondStorage();
        uint256 facetCount = ds.facetAddresses.length();
        facets_ = new Facet[](facetCount);
        for (uint256 facet; facet < facetCount; ++facet) {
            address facetAddr = ds.facetAddresses.at(facet);
            facets_[facet].facetAddress = facetAddr;
            facets_[facet].functionSelectors = ds.facetToSelectors[facetAddr]._values();
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory) {
        return LibDiamond._diamondStorage().facetToSelectors[_facet]._values();
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory) {
        return LibDiamond._diamondStorage().facetAddresses.values();
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address) {
        return LibDiamond._diamondStorage().selectorToFacet[_functionSelector];
    }

    /// @notice Query if a contract implements an interface
    /// @param _interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return LibERC165._supportsInterface(_interfaceId);
    }
}
