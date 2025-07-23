// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//*//////////////////////////////////////////////////////////////////////////
//                           DIAMOND LIBRARY ERRORS
//////////////////////////////////////////////////////////////////////////*//

/// @notice Thrown when a diamond cut is attempted with no facets specified
error NoFacetsInDiamondCut();

/// @notice Thrown when attempting a diamond cut with no function selectors specified to add
error NoSelectorsGivenToAdd();

/// @notice Thrown when no function selectors are provided for a given facet in a cut
/// @param facetAddress The facet contract address for which selectors were expected
error NoSelectorsProvidedForFacetForCut(address facetAddress);

/// @notice Thrown when trying to add selectors under the zero address (invalid facet)
/// @param selectors The selectors attempted to be added
error CannotAddSelectorsToZeroAddress(bytes4[] selectors);

/// @notice Thrown when verifying a facet contract but finding no deployed bytecode
/// @param contractAddress The address checked for deployed bytecode
error NoBytecodeAtAddress(address contractAddress);

/// @notice Thrown when an unrecognized action is passed to the diamond cut
/// @param action The raw uint8 action value provided
error IncorrectFacetCutAction(uint8 action);

error FacetAlreadyAdded(address facet);

/// @notice Thrown when adding a function selector that already exists in the diamond
/// @param selector The selector that is already present
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 selector);

/// @notice Thrown when replacing selectors but the replacement facet address is zero
/// @param selectors The selectors attempted to be replaced
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] selectors);

/// @notice Thrown when attempting to replace a function in the diamond
/// @param selector The selector of the immutable function
error CannotReplaceImmutableFunction(bytes4 selector);

/// @notice Thrown when replacing a function with the same implementation from the same facet
/// @param selector The selector that would result in a no-op replace
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 selector);

/// @notice Thrown when attempting to replace a function that does not currently exist
/// @param selector The selector missing from the diamond
error CannotReplaceFunctionThatDoesNotExists(bytes4 selector);

/// @notice Thrown when removing a facet but the facet address provided is non-zero
/// @param facetAddress The address that should have been zero for removals
error RemoveFacetAddressMustBeZeroAddress(address facetAddress);

/// @notice Thrown when attempting to remove a function selector that isn’t in the diamond
/// @param selector The selector that could not be found
error CannotRemoveFunctionThatDoesNotExist(bytes4 selector);

error CannotRemoveFacetThatDoesNotExist(address facetAddress);

/// @notice Thrown when attempting to remove an immutable function
/// @param selector The selector of the immutable function
error CannotRemoveImmutableFunction(bytes4 selector);

/// @notice Thrown when the initialization call following a diamond cut reverts
/// @param initAddress The address of the init contract that reverted
/// @param data The calldata passed to the init contract
error InitializationFunctionReverted(address initAddress, bytes data);

//*//////////////////////////////////////////////////////////////////////////
//                               DIAMOND ERRORS
//////////////////////////////////////////////////////////////////////////*//

/// @notice Thrown when a called function selector does not map to any facet
/// @param functionSelector The selector of the function attempted
error FunctionDoesNotExist(bytes4 functionSelector);

//*//////////////////////////////////////////////////////////////////////////
//                         DIAMOND MULTI INIT ERRORS
//////////////////////////////////////////////////////////////////////////*//

/// @notice Thrown when the length of the address array does not match the length of the calldata array.
/// @dev Used in initializer logic to ensure one-to-one mapping between addresses and initialization calldata.
error AddressAndCalldataLengthDoNotMatch();
