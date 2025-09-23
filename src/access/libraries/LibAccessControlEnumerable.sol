// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAccessControl} from "@diamond/access/libraries/LibAccessControl.sol";
import {
    ACCESS_CONTROL_ENUMERABLE_STORAGE_SLOT,
    AccessControlEnumerableStorage,
    EnumerableSet
} from "@diamond/access/libraries/storage/AccessControlEnumerableStorage.sol";
import {LibERC165} from "@diamond/utils/introspection/LibERC165.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";

library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    function _accessControlEnumerableStorage() internal pure returns (AccessControlEnumerableStorage storage acs_) {
        assembly {
            acs_.slot := ACCESS_CONTROL_ENUMERABLE_STORAGE_SLOT
        }
    }

    function _registerInterface() internal {
        LibAccessControl._registerInterface();
        LibERC165._registerInterface(type(IAccessControlEnumerable).interfaceId);
    }

    /**
     * @dev Adds a member to a role.
     */
    function _addRoleMember(bytes32 _role, address _account) internal {
        _accessControlEnumerableStorage().roleMembers[_role].add(_account);
    }

    /**
     * @dev Removes a member from a role.
     */
    function _removeRoleMember(bytes32 _role, address _account) internal {
        _accessControlEnumerableStorage().roleMembers[_role].remove(_account);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function _getRoleMember(bytes32 _role, uint256 _index) internal view returns (address) {
        return _accessControlEnumerableStorage().roleMembers[_role].at(_index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function _getRoleMemberCount(bytes32 _role) internal view returns (uint256) {
        return _accessControlEnumerableStorage().roleMembers[_role].length();
    }

    /**
     * @dev Return all accounts that have `role`
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _getRoleMembers(bytes32 _role) internal view returns (address[] memory) {
        return _accessControlEnumerableStorage().roleMembers[_role].values();
    }
}
