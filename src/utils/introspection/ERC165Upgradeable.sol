// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@diamond/utils/initializable/Initializable.sol";
import {IERC165, LibERC165} from "@diamond/utils/introspection/LibERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    using LibERC165 for bytes4;

    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
        _registerInterface(type(IERC165).interfaceId);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to check if a contract implements an interface.
     * @param interfaceId The interface identifier.
     */
    function _supportsInterface(bytes4 interfaceId) internal view virtual returns (bool) {
        return interfaceId._supportsInterface();
    }

    /**
     * @dev Internal function to register an interface.
     * @param _interfaceId The interface identifier.
     */
    function _registerInterface(bytes4 _interfaceId) internal virtual {
        _interfaceId._registerInterface();
    }
}
