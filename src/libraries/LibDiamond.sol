// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FacetCut, FacetCutAction} from "@diamond/libraries/types/DiamondTypes.sol";
import {DiamondCut} from "@diamond/libraries/logs/DiamondLogs.sol";
import {
    CannotAddFunctionToDiamondThatAlreadyExists,
    CannotAddSelectorsToZeroAddress,
    CannotRemoveFunctionThatDoesNotExist,
    CannotRemoveImmutableFunction,
    CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet,
    IncorrectFacetCutAction,
    InitializationFunctionReverted,
    NoBytecodeAtAddress,
    NoFacetsInDiamondCut,
    NoSelectorsGivenToAdd,
    NoSelectorsProvidedForFacetForCut,
    RemoveFacetAddressMustBeZeroAddress
} from "@diamond/libraries/errors/DiamondErrors.sol";

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

/// @notice Internal library providing core functionality for EIP-2535 Diamond proxy management.
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/libraries/LibDiamond.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/libraries/LibDiamond.sol)
///
/// @dev Defines the diamond storage layout and implements the `_diamondCut` operation and storage accessors
library LibDiamond {
    //*//////////////////////////////////////////////////////////////////////////
    //                              DIAMOND STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    // keccak256(abi.encode(uint256(keccak256("diamond.standard.diamond.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant DIAMOND_STORAGE_LOCATION =
        0x44fefae66705534388ac21ba5f0775616856a675b8eaea9bb0b2507f06238700;

    /// @dev Get the diamond storage.
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_LOCATION;
        assembly {
            ds.slot := position
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             DIAMOND FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Add/replace/remove any number of functions and optionally execute
    ///      a function with delegatecall.
    /// @param _facetCuts Contains the facet addresses, cut actions and function selectors.
    /// @param _init The address of the contract or facet to execute `data`.
    /// @param _calldata A function call, including function selector and arguments.
    function _diamondCut(FacetCut[] memory _facetCuts, address _init, bytes memory _calldata) internal {
        uint256 facetCutsLength = _facetCuts.length;
        if (facetCutsLength == 0) revert NoFacetsInDiamondCut();
        for (uint256 facetIndex; facetIndex < facetCutsLength; facetIndex++) {
            FacetCutAction action = _facetCuts[facetIndex].action;
            if (action == FacetCutAction.Add) {
                _addFunctions(_facetCuts[facetIndex].facetAddress, _facetCuts[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                _replaceFunctions(_facetCuts[facetIndex].facetAddress, _facetCuts[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                _removeFunctions(_facetCuts[facetIndex].facetAddress, _facetCuts[facetIndex].functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_facetCuts, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    /// @dev Add functions to the diamond.
    /// @param _facetAddress The address of the facet to add functions to.
    /// @param _functionSelectors The function selectors to add to the facet.
    function _addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (functionSelectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        DiamondStorage storage ds = diamondStorage();
        uint96 selectorPosition = uint96(ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.length);
        // Add new facet address if it does not exist
        if (selectorPosition == 0) {
            _addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            _addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /// @dev Replace functions in the diamond.
    /// @param _facetAddress The address of the facet to replace functions from.
    /// @param _functionSelectors The function selectors to replace in the facet.
    function _replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (functionSelectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        DiamondStorage storage ds = diamondStorage();
        uint96 selectorPosition = uint96(ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            _addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            _removeFunction(ds, oldFacetAddress, selector);
            _addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /// @dev Remove functions from the diamond.
    /// @param _facetAddress The address of the facet to remove functions from.
    /// @param _functionSelectors The function selectors to remove from the facet.
    function _removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (_facetAddress != address(0)) revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        if (functionSelectorsLength == 0) revert NoSelectorsProvidedForFacetForCut(_facetAddress);
        DiamondStorage storage ds = diamondStorage();
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            _removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /// @dev Add a facet address to the diamond.
    /// @param ds Diamond storage.
    /// @param _facetAddress The address of the facet to add.
    function _addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        _enforceHasContractCode(_facetAddress);
        ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    /// @dev Add a function to the diamond.
    /// @param ds Diamond storage.
    /// @param _selector The function selector to add.
    /// @param _selectorPosition The position of the function selector in the facetToSelectorsAndPosition.functionSelectors array.
    /// @param _facetAddress The address of the facet to add the function selector to.
    function _addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress)
        internal
    {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    /// @dev Remove a function from the diamond.
    /// @param ds Diamond storage.
    /// @param _facetAddress The address of the facet to remove the function from.
    /// @param _selector The function selector to remove.
    function _removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) revert CannotRemoveFunctionThatDoesNotExist(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert CannotRemoveImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetToSelectorsAndPosition[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition;
        }
    }

    /// @dev Initialize the diamond cut.
    /// @param _init The address of the contract or facet to execute `data`.
    /// @param _calldata A function call, including function selector and arguments.
    function _initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        _enforceHasContractCode(_init);
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @dev Enforce that the contract has bytecode.
    /// @param _contract The address of the contract to check.
    function _enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract);
        }
    }
}
