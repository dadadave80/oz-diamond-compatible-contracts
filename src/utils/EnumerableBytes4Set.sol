// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library EnumerableBytes4Set {
    struct Set {
        // Storage of set values
        bytes4[] values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes4 value => uint256) positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes4 value) internal returns (bool) {
        if (!_contains(set, value)) {
            set.values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set.positions[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes4 value) internal returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set.positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set.values.length - 1;

            if (valueIndex != lastIndex) {
                bytes4 lastValue = set.values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set.values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set.positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set.values.pop();

            // Delete the tracked position for the deleted slot
            delete set.positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes all the values from a set. O(n).
     *
     * WARNING: This function has an unbounded cost that scales with set size. Developers should keep in mind that
     * using it may render the function uncallable if the set grows to the point where clearing it consumes too much
     * gas to fit in a block.
     */
    function _clear(Set storage set) internal {
        uint256 len = _length(set);
        for (uint256 i = 0; i < len; ++i) {
            delete set.positions[set.values[i]];
        }
        bytes4[] storage values = set.values;
        assembly ("memory-safe") {
            sstore(values.slot, 0)
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes4 value) internal view returns (bool) {
        return set.positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) internal view returns (uint256) {
        return set.values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) internal view returns (bytes4) {
        return set.values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) internal view returns (bytes4[] memory) {
        return set.values;
    }
}
