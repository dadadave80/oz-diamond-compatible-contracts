// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@diamond/access/AccessControlUpgradeable.sol";
import {LibAccessControlEnumerable} from "@diamond/access/libraries/LibAccessControlEnumerable.sol";

import {Initializable} from "@diamond/utils/initializable/Initializable.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";

abstract contract AccessControlEnumerableUpgradeable is
    Initializable,
    IAccessControlEnumerable,
    AccessControlUpgradeable
{
    using LibAccessControlEnumerable for *;

    function __AccessControlEnumerable_init(address admin) internal onlyInitializing {
        __AccessControlEnumerable_init_unchained(admin);
    }

    function __AccessControlEnumerable_init_facet(address admin) internal onlyInitializing {
        __AccessControlEnumerable_init_unchained(admin);
        LibAccessControlEnumerable._registerInterface();
    }

    function __AccessControlEnumerable_init_unchained(address admin) internal onlyInitializing {
        __AccessControl_init_unchained(admin);
    }

    /**
     * @dev Internal function to check if a contract implements an interface.
     * @param interfaceId The interface identifier.
     */
    function _supportsInterface(bytes4 interfaceId) internal view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super._supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address) {
        return role._getRoleMember(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual returns (uint256) {
        return role._getRoleMemberCount();
    }

    /**
     * @dev Return all accounts that have `role`
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function getRoleMembers(bytes32 role) public view virtual returns (address[] memory) {
        return role._getRoleMembers();
    }

    /**
     * @dev Overload {AccessControl-_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool granted) {
        granted = super._grantRole(role, account);
        if (granted) {
            _addRoleMember(role, account);
        }
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool revoked) {
        revoked = super._revokeRole(role, account);
        if (revoked) {
            _removeRoleMember(role, account);
        }
    }

    /**
     * @dev Adds a member to a role.
     */
    function _addRoleMember(bytes32 _role, address _account) internal virtual {
        _role._addRoleMember(_account);
    }

    /**
     * @dev Removes a member from a role.
     */
    function _removeRoleMember(bytes32 _role, address _account) internal virtual {
        _role._removeRoleMember(_account);
    }
}
