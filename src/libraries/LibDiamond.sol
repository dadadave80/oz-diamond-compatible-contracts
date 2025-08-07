// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {
    FacetCut,
    FacetCutAction,
    DiamondStorage,
    DIAMOND_STORAGE_SLOT
} from "@diamond/libraries/types/DiamondStorage.sol";
import "@diamond/libraries/logs/DiamondLogs.sol";
import "@diamond/libraries/errors/DiamondErrors.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @notice Internal library providing core functionality for EIP-2535 Diamond proxy management.
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/libraries/LibDiamond.sol)
///
/// @dev Defines the diamond storage layout and implements the `_diamondCut` operation and storage accessors
library LibDiamond {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    //*//////////////////////////////////////////////////////////////////////////
    //                              DIAMOND STORAGE
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Get the diamond storage.
    function _diamondStorage() internal pure returns (DiamondStorage storage ds_) {
        assembly {
            ds_.slot := DIAMOND_STORAGE_SLOT
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
        for (uint256 facetIndex; facetIndex < facetCutsLength;) {
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
            unchecked {
                ++facetIndex;
            }
        }
        emit DiamondCut(_facetCuts, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    /// @dev Add functions to the diamond.
    /// @param _facetAddress The address of the facet to add functions to.
    /// @param _selectors The function selectors to add to the facet.
    function _addFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        uint256 selectorsLength = _selectors.length;
        if (selectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) revert CannotAddSelectorsToZeroAddress(_selectors);
        DiamondStorage storage ds = _diamondStorage();
        // Add new facet address if it does not exist
        if (ds.facetToSelectors[_facetAddress].length() == 0) _addFacet(ds, _facetAddress);
        for (uint256 selectorIndex; selectorIndex < selectorsLength;) {
            bytes4 selector = _selectors[selectorIndex];
            _addFunction(ds, selector, _facetAddress);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /// @dev Replace functions in the diamond.
    /// @param _facetAddress The address of the facet to replace functions from.
    /// @param _selectors The function selectors to replace in the facet.
    function _replaceFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        uint256 functionSelectorsLength = _selectors.length;
        if (functionSelectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) revert CannotAddSelectorsToZeroAddress(_selectors);
        DiamondStorage storage ds = _diamondStorage();
        // Add new facet address if it does not exist
        if (ds.facetToSelectors[_facetAddress].length() == 0) _addFacet(ds, _facetAddress);
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _selectors[selectorIndex];
            _removeFunction(ds, ds.selectorToFacet[selector], selector);
            _addFunction(ds, selector, _facetAddress);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /// @dev Remove functions from the diamond.
    /// @param _facetAddress The address of the facet to remove functions from.
    /// @param _selectors The function selectors to remove from the facet.
    function _removeFunctions(address _facetAddress, bytes4[] memory _selectors) internal {
        uint256 functionSelectorsLength = _selectors.length;
        if (_facetAddress != address(0)) revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        if (functionSelectorsLength == 0) revert NoSelectorsProvidedForFacetForCut(_facetAddress);
        DiamondStorage storage ds = _diamondStorage();
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _selectors[selectorIndex];
            _removeFunction(ds, ds.selectorToFacet[selector], selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /// @dev Add a facet address to the diamond.
    /// @param _ds Diamond storage.
    /// @param _facetAddress The address of the facet to add.
    function _addFacet(DiamondStorage storage _ds, address _facetAddress) internal {
        _enforceHasContractCode(_facetAddress);
        if (!_ds.facetAddresses.add(_facetAddress)) revert FacetAlreadyAdded(_facetAddress);
    }

    /// @dev Add a function to the diamond.
    /// @param _ds Diamond storage.
    /// @param _selector The function selector to add.
    /// @param _facetAddress The address of the facet to add the function selector to.
    function _addFunction(DiamondStorage storage _ds, bytes4 _selector, address _facetAddress) internal {
        _ds.selectorToFacet[_selector] = _facetAddress;
        if (!_ds.facetToSelectors[_facetAddress].add(_selector)) {
            revert CannotAddFunctionToDiamondThatAlreadyExists(_selector);
        }
    }

    /// @dev Remove a function from the diamond.
    /// @param _ds Diamond storage.
    /// @param _facetAddress The address of the facet to remove the function from.
    /// @param _selector The function selector to remove.
    function _removeFunction(DiamondStorage storage _ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) revert CannotRemoveFunctionThatDoesNotExist(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert CannotRemoveImmutableFunction(_selector);

        if (!_ds.facetToSelectors[_facetAddress].remove(_selector)) {
            revert CannotRemoveFunctionThatDoesNotExist(_selector);
        }
        delete _ds.selectorToFacet[_selector];

        // when there are no more selectors for this facet address, delete the facet address
        if (_ds.facetToSelectors[_facetAddress].length() == 0) {
            if (!_ds.facetAddresses.remove(_facetAddress)) {
                revert CannotRemoveFacetThatDoesNotExist(_facetAddress);
            }
        }
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                            DIAMOND INITIALIZER
    //////////////////////////////////////////////////////////////////////////*//

    /// @dev Initialize the diamond cut.
    /// @param _init The address of the contract or facet to execute `data`.
    /// @param _calldata A function call, including function selector and arguments.
    function _initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        _enforceHasContractCode(_init);
        (bool success, bytes memory err) = _init.delegatecall(_calldata);
        if (!success) {
            if (err.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(err)
                    revert(add(32, err), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @dev Enforce that the contract has bytecode.
    /// @param _contract The address of the contract to check.
    function _enforceHasContractCode(address _contract) internal view {
        if (_contract.code.length == 0) revert NoBytecodeAtAddress(_contract);
    }
}
