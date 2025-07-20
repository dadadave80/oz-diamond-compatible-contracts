// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*//////////////////////////////////////////////////////////////////////////
//                           DIAMOND STORAGE TYPES
//////////////////////////////////////////////////////////////////////////*//

/// @dev This struct is used to store the facet address and position of the
///      function selector in the facetToSelectorsAndPosition.functionSelectors
///      array.
struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition;
}

/// @dev This struct is used to store the function selectors and position of
///      the facet address in the facetAddresses array.
struct FacetFunctionSelectorsAndPosition {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition;
}

/// @notice Storage structure for managing facets and interface support in a Diamond (EIP-2535) proxy
/// @dev Tracks function selector mappings, facet lists, and ERC-165 interface support
/// @custom:storage-location erc7201:diamond.standard.diamond.storage
struct DiamondStorage {
    /// @notice Maps each function selector to the facet address and selector’s position in that facet
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    /// @notice Maps each facet address to its function selectors and the facet’s position in the global list
    mapping(address => FacetFunctionSelectorsAndPosition) facetToSelectorsAndPosition;
    /// @notice Array of all facet addresses registered in the diamond
    address[] facetAddresses;
    /// @notice Tracks which interface IDs (ERC-165) are supported by the diamond
    mapping(bytes4 => bool) supportedInterfaces;
}

// keccak256(abi.encode(uint256(keccak256("diamond.standard.diamond.storage")) - 1)) & ~bytes32(uint256(0xff));
bytes32 constant DIAMOND_STORAGE_LOCATION = 0x44fefae66705534388ac21ba5f0775616856a675b8eaea9bb0b2507f06238700;

//*//////////////////////////////////////////////////////////////////////////
//                             DIAMOND CUT TYPES
//////////////////////////////////////////////////////////////////////////*//

/// @notice Actions that can be performed on a facet during a diamond cut
/// @dev `Add` will add new function selectors, `Replace` will swap existing
///       selectors to a new facet, `Remove` will delete selectors
enum FacetCutAction {
    Add,
    Replace,
    Remove
}

/// @notice Defines an operation (add/replace/remove) to perform on a facet
/// @param facetAddress The address of the facet contract to operate on
/// @param action The action to perform (Add, Replace, Remove)
/// @param functionSelectors List of function selectors to apply the action to
struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

/// @notice Initialization parameters passed to the Diamond constructor
/// @param owner The address that will be granted the initial ownership/roles
/// @param init Optional address of a contract to call after the cut (use zero address for none)
/// @param initData Calldata to pass to the init contract (if any)
struct DiamondArgs {
    address owner;
    address init;
    bytes initData;
}

/// @notice Struct representing a facet in a diamond contract.
/// @dev Used for introspection of facet data through loupe functions.
/// @param facetAddress The address of the facet contract.
/// @param functionSelectors The list of function selectors provided by this facet.
struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}
