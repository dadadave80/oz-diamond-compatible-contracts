// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {LibERC165} from "@diamond/utils/introspection/LibERC165.sol";

/**
 * @dev The caller account is not authorized to perform an operation.
 */
error OwnableUnauthorizedAccount(address account);

/**
 * @dev The owner is not a valid owner account. (eg. `address(0)`)
 */
error OwnableInvalidOwner(address owner);

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant OWNABLE_STORAGE_SLOT = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

/// @custom:storage-location erc7201:openzeppelin.storage.Ownable
struct OwnableStorage {
    address owner;
}

library LibOwnable {
    function _ownableStorage() internal pure returns (OwnableStorage storage os_) {
        assembly {
            os_.slot := OWNABLE_STORAGE_SLOT
        }
    }

    function _init(address _initialOwner) internal {
        /// @dev type(IERC173).interfaceId
        LibERC165._registerInterface(0x7f5828d0);
        if (_initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(_initialOwner);
    }

    function _owner() internal view returns (address) {
        return _ownableStorage().owner;
    }

    function _checkOwner() internal view {
        if (_owner() != LibContext._msgSender()) {
            revert OwnableUnauthorizedAccount(LibContext._msgSender());
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address _newOwner) internal {
        OwnableStorage storage os = _ownableStorage();
        address oldOwner = os.owner;
        os.owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}
