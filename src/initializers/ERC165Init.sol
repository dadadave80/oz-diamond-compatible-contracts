// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DiamondStorage, LibDiamond} from "@diamond/proxy/diamond/libraries/LibDiamond.sol";
import {ERC165Storage, LibERC165} from "@diamond/utils/introspection/LibERC165.sol";

/// @notice Provides an initializer to register standard interface support (ERC-165, ERC-173, IDiamondCut, IDiamondLoupe)
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/upgradeInitializers/DiamondInit.sol)
///
/// @dev Intended to be called as the `initERC165` function in a diamond cut to set up ERC-165 interface IDs
contract ERC165Init {
    /// @notice Initialize the contract with the ERC165 interface support.
    /// @dev This function is called during the diamond cut process to set up
    ///      the initial state of the contract.
    function registerInterfaces() external {
        /// @dev type(ERC165).interfaceId
        LibERC165._registerInterface(0x01ffc9a7);
        /// @dev type(IDiamondCut).interfaceId
        LibERC165._registerInterface(0x1f931c1c);
        /// @dev type(IDiamondLoupe).interfaceId
        LibERC165._registerInterface(0x48e2b093);
        /// @dev type(IERC173).interfaceId for Ownable
        LibERC165._registerInterface(0x7f5828d0);
    }
}
