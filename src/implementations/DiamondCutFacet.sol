// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";
import {FacetCut} from "@diamond/proxy/diamond/libraries/DiamondStorage.sol";
import {LibDiamond} from "@diamond/proxy/diamond/libraries/LibDiamond.sol";

/// @notice Simple single owner and multiroles authorization mixin.
/// @author David Dada
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/facets/DiamondCutFacet.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/facets/DiamondCutFacet.sol)
///
/// @dev Note:
/// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
/// The loupe functions are required by the EIP2535 Diamonds standard.
contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external payable {
        // Check that the caller is the owner
        LibOwnable._checkOwner();
        // Call the diamond cut function from the library
        LibDiamond._diamondCut(_diamondCut, _init, _calldata);
    }
}
