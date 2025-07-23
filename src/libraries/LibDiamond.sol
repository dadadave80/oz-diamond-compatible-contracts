// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {
    FacetCut,
    FacetCutAction,
    DiamondStorage,
    DIAMOND_STORAGE_LOCATION
} from "@diamond/libraries/types/DiamondTypes.sol";
import {DiamondCut} from "@diamond/libraries/logs/DiamondLogs.sol";
import {
    CannotAddFunctionToDiamondThatAlreadyExists,
    CannotAddSelectorsToZeroAddress,
    CannotRemoveFunctionThatDoesNotExist,
    CannotRemoveFacetThatDoesNotExist,
    CannotRemoveImmutableFunction,
    CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet,
    IncorrectFacetCutAction,
    FacetAlreadyAdded,
    InitializationFunctionReverted,
    NoBytecodeAtAddress,
    NoFacetsInDiamondCut,
    NoSelectorsGivenToAdd,
    NoSelectorsProvidedForFacetForCut,
    RemoveFacetAddressMustBeZeroAddress
} from "@diamond/libraries/errors/DiamondErrors.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @notice Internal library providing core functionality for EIP-2535 Diamond proxy management.
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/libraries/LibDiamond.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/libraries/LibDiamond.sol)
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
        bytes32 position = DIAMOND_STORAGE_LOCATION;
        assembly {
            ds_.slot := position
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
    /// @param _functionSelectors The function selectors to add to the facet.
    function _addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (functionSelectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        DiamondStorage storage ds = _diamondStorage();
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

    function _addFunctionsEnumerable(address _facetAddress, bytes4[] memory _selectors) internal {
        uint256 selectorsLength = _selectors.length;
        if (selectorsLength == 0) revert NoSelectorsGivenToAdd();
        if (_facetAddress == address(0)) revert CannotAddSelectorsToZeroAddress(_selectors);
        DiamondStorage storage ds = _diamondStorage();
        // Add new facet address if it does not exist
        if (ds.facetToSelectors[_facetAddress].length() == 0) {
            if (!_addFacetEnumerable(ds, _facetAddress)) revert FacetAlreadyAdded(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < selectorsLength;) {
            bytes4 selector = _selectors[selectorIndex];
            if (!_addFunctionEnumerable(ds, selector, _facetAddress)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
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
        DiamondStorage storage ds = _diamondStorage();
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
        DiamondStorage storage ds = _diamondStorage();
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            _removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    function _removeFunctionsEnumerable(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        uint256 functionSelectorsLength = _functionSelectors.length;
        if (_facetAddress != address(0)) revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        if (functionSelectorsLength == 0) revert NoSelectorsProvidedForFacetForCut(_facetAddress);
        DiamondStorage storage ds = _diamondStorage();
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            _removeFunctionEnumerable(ds, ds.selectorToFacet[selector], selector);
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
        _ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition = _ds.facetAddresses.length;
        _ds.facetAddresses.push(_facetAddress);
    }

    function _addFacetEnumerable(DiamondStorage storage _ds, address _facetAddress) internal returns (bool) {
        _enforceHasContractCode(_facetAddress);
        return _ds.enumerableFacetAddresses.add(_facetAddress);
    }

    /// @dev Add a function to the diamond.
    /// @param _ds Diamond storage.
    /// @param _selector The function selector to add.
    /// @param _selectorPosition The position of the function selector in the facetToSelectorsAndPosition.functionSelectors array.
    /// @param _facetAddress The address of the facet to add the function selector to.
    function _addFunction(DiamondStorage storage _ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress)
        internal
    {
        _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.push(_selector);
        _ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function _addFunctionEnumerable(DiamondStorage storage _ds, bytes4 _selector, address _facetAddress)
        internal
        returns (bool)
    {
        _ds.selectorToFacet[_selector] = _facetAddress;
        return _ds.facetToSelectors[_facetAddress].add(_selector);
    }

    /// @dev Remove a function from the diamond.
    /// @param _ds Diamond storage.
    /// @param _facetAddress The address of the facet to remove the function from.
    /// @param _selector The function selector to remove.
    function _removeFunction(DiamondStorage storage _ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) revert CannotRemoveFunctionThatDoesNotExist(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert CannotRemoveImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors[lastSelectorPosition];
            _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        _ds.facetToSelectorsAndPosition[_facetAddress].functionSelectors.pop();
        delete _ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = _ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = _ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _ds.facetAddresses[lastFacetAddressPosition];
                _ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                _ds.facetToSelectorsAndPosition[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            _ds.facetAddresses.pop();
            delete _ds.facetToSelectorsAndPosition[_facetAddress].facetAddressPosition;
        }
    }

    function _removeFunctionEnumerable(DiamondStorage storage _ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) revert CannotRemoveFunctionThatDoesNotExist(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert CannotRemoveImmutableFunction(_selector);

        if (!_ds.facetToSelectors[_facetAddress].remove(_selector)) {
            revert CannotRemoveFunctionThatDoesNotExist(_selector);
        }
        delete _ds.selectorToFacet[_selector];

        // when there are no more selectors for this facet address, delete the facet address
        if (_ds.facetToSelectors[_facetAddress].length() == 0) {
            if (!_ds.enumerableFacetAddresses.remove(_facetAddress)) {
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
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract);
        }
    }
}
