// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDiamondLoupe} from "@diamond/interfaces/IDiamondLoupe.sol";
import {Facet} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";

/// @notice A utility contract providing helper functions for working with diamond facets and selectors.
/// @author David Dada
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/test/HelperContract.sol)
///
/// @dev Includes support for generating selectors using Foundry FFI, array manipulation, and facet inspection.
library Utils {
    /// @notice Removes an element from a bytes4 array at the given index.
    /// @param _index The index of the element to remove.
    /// @param _array The original array.
    /// @return array_ A new array with the element at `_index` removed.
    function removeElement(uint256 _index, bytes4[] memory _array) public pure returns (bytes4[] memory array_) {
        uint256 arrayLength = _array.length;
        array_ = new bytes4[](arrayLength - 1);
        uint256 j = 0;
        for (uint256 i; i < arrayLength; ++i) {
            if (i != _index) {
                array_[j] = _array[i];
                j += 1;
            }
        }
    }

    /// @notice Removes a specific selector from a bytes4 array.
    /// @param el The selector to remove.
    /// @param _array The original array.
    /// @return array_ A new array without the specified selector.
    function removeElement(bytes4 el, bytes4[] memory _array) public pure returns (bytes4[] memory array_) {
        uint256 arrayLength = _array.length;
        for (uint256 i; i < arrayLength; ++i) {
            if (_array[i] == el) {
                array_ = removeElement(i, _array);
            }
        }
    }

    /// @notice Checks if a bytes4 array contains a specific selector.
    /// @param _array The array to check.
    /// @param _el The selector to look for.
    /// @return `true` if the selector is found, `false` otherwise.
    function containsElement(bytes4[] memory _array, bytes4 _el) public pure returns (bool) {
        uint256 arrayLength = _array.length;
        for (uint256 i; i < arrayLength; ++i) {
            if (_array[i] == _el) {
                return true;
            }
        }
        return false;
    }

    /// @notice Checks if an address array contains a specific address.
    /// @param _array The array to check.
    /// @param _el The address to look for.
    /// @return `true` if the address is found, `false` otherwise.
    function containsElement(address[] memory _array, address _el) public pure returns (bool) {
        uint256 arrayLength = _array.length;
        for (uint256 i; i < arrayLength; ++i) {
            if (_array[i] == _el) {
                return true;
            }
        }
        return false;
    }

    /// @notice Determines if two arrays of function selectors have the same members.
    /// @param _array1 The first array.
    /// @param _array2 The second array.
    /// @return `true` if the arrays contain the same elements (regardless of order), `false` otherwise.
    function sameMembers(bytes4[] memory _array1, bytes4[] memory _array2) public pure returns (bool) {
        uint256 array1Length = _array1.length;
        if (array1Length != _array2.length) {
            return false;
        }
        for (uint256 i; i < array1Length; ++i) {
            if (containsElement(_array1, _array2[i])) {
                return true;
            }
        }
        return false;
    }

    /// @notice Retrieves all function selectors from all facets of a diamond contract.
    /// @param _diamondAddress The address of the diamond contract.
    /// @return selectors_ An array of all function selectors used in the diamond.
    function getAllSelectors(address _diamondAddress) public view returns (bytes4[] memory selectors_) {
        Facet[] memory facetList = IDiamondLoupe(_diamondAddress).facets();

        uint256 facetListLength = facetList.length;
        uint256 len = 0;
        for (uint256 i; i < facetListLength; ++i) {
            len += facetList[i].functionSelectors.length;
        }

        uint256 pos = 0;
        selectors_ = new bytes4[](len);
        for (uint256 i; i < facetListLength; ++i) {
            for (uint256 j; j < facetList[i].functionSelectors.length; ++j) {
                selectors_[pos] = facetList[i].functionSelectors[j];
                pos += 1;
            }
        }
    }
}
