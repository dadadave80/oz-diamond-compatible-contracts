// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165Storage, ERC165_STORAGE_SLOT} from "@diamond/utils/introspection/ERC165Storage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

library LibERC165 {
    function _ERC165Storage() internal pure returns (ERC165Storage storage $) {
        assembly {
            $.slot := ERC165_STORAGE_SLOT
        }
    }

    /**
     * @dev Internal function to check if a contract implements an interface.
     * @param _interfaceId The interface identifier.
     */
    function _supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        return type(IERC165).interfaceId == _interfaceId || _ERC165Storage().supportedInterfaces[_interfaceId];
    }

    /**
     * @dev Internal function to register an interface.
     * @param _interfaceId The interface identifier.
     */
    function _registerInterface(bytes4 _interfaceId) internal {
        _ERC165Storage().supportedInterfaces[_interfaceId] = true;
    }
}
