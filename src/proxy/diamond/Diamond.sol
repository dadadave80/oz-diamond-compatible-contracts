// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionDoesNotExist} from "@diamond/proxy/diamond/libraries/DiamondErrors.sol";
import {FacetCut, LibDiamond} from "@diamond/proxy/diamond/libraries/LibDiamond.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⡤⣶⣾⠟⠋⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠛⠛⠓⠶⠤⣤⣀⡀
⠀⠀⠀⠀⠀⠀⠀⢠⣴⠶⠛⠿⢿⣶⣿⡋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠓⠲⢦⣤⣀⣀
⠀⠀⠀⠀⢀⣴⡾⠋⠀⠀⢀⣴⠟⠁⠈⠛⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠲⢶⣄
⠀⠀⣠⣶⡿⠋⠀⠀⠀⣠⠟⠁⠀⠀⠀⣀⣨⣿⣶⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⣦⡀
⣰⣾⡿⠋⠀⠀⣀⣤⣾⣥⠶⠒⠚⠋⠉⠉⠁⠀⠘⣧⠈⠉⠛⠒⠶⣤⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣝⠷⣤⡀
⣿⡿⠒⠛⠋⢉⡽⠋⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣧⠀⠀⠀⠀⠀⠀⠉⠉⠛⠒⢶⣤⣤⣤⣤⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⠶⠛⠙⣟⠚⠻⢶⣄
⢻⣷⡀⢀⣴⠏⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡆⠀⠀⠀⣀⣤⣤⠴⠖⠚⠋⠉⠛⢦⣄⡀⠀⠉⠉⠉⠉⠉⠉⠉⠉⣹⡿⠿⣥⡀⠀⠀⠀⠹⣆⠀⠀⠹⣧⡀
⠈⢿⡹⣿⡁⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⡴⣿⣶⠛⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⢦⣄⠀⠀⠀⠀⠀⢀⡾⠋⠀⠀⠈⠙⠳⣦⡀⠀⢻⡄⠀⠀⠹⣷⡀
⠀⠈⣷⣬⣿⣦⣄⠀⣿⠀⣀⣠⣤⡴⠖⠚⠋⠉⠁⠀⠀⡏⠈⢷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣦⡀⢀⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⢦⣷⡀⠀⠀⠹⣿⡄
⠀⠀⠈⠻⣆⠉⠙⣿⡙⠻⢯⣀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠃⠀⠀⠙⢷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡿⡿⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡟⢿⢦⣄⠀⠹⣿⣆
⠀⠀⠀⠀⠈⢷⣄⠀⠙⢷⣄⣉⡻⣶⣄⣀⠀⠀⠀⢀⣿⠀⠀⠀⠀⠀⠻⣦⡀⠀⠀⠀⠀⠀⠀⢀⣠⡴⠞⠉⠀⢸⡇⠀⠙⠳⣦⡀⠀⠀⠀⠀⠀⠀⠀⣾⠀⠈⣧⠈⠙⢦⣽⣼
⠀⠀⠀⠀⠀⠀⠙⢧⡄⠀⠻⣯⡉⠉⠉⠛⢿⣍⡉⠉⠙⠷⣤⣀⠀⠀⠀⠈⠻⣦⠀⠀⣀⣤⠶⠋⠁⠀⠀⠀⠀⢸⠃⠀⠀⠀⠀⠙⠷⣤⡀⠀⠀⠀⣼⠃⠀⠀⠘⣦⠀⢀⣬⡿
⠀⠀⠀⠀⠀⠀⠀⠀⠻⣦⡀⢹⣷⣄⠀⠀⠀⠈⠙⢶⡶⠶⠶⠯⣭⣛⣓⡲⠶⠾⠷⠿⣭⣀⣀⠀⠀⠀⠀⠀⣀⣾⠀⠀⠀⠀⠀⠀⠀⠈⠛⢶⣄⣰⠏⠀⠀⢀⣠⡿⢟⡿⠋
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⢻⣟⢷⡄⠀⠀⠀⠈⢷⠀⠀⠀⠀⠀⠈⠉⠓⢶⣦⠴⠶⠾⠭⣭⣍⣉⣉⠉⠉⠉⠙⠳⢶⣤⣄⣤⡴⠶⠖⠛⠋⣙⣿⠷⠿⠿⣧⣶⠟⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⣽⣆⠻⣦⡀⠀⠀⠘⣇⠀⠀⠀⠀⠀⠀⠀⣼⣷⠀⠀⠀⠀⠀⠀⠈⠉⢛⣶⠶⠛⠉⠉⠁⠀⠉⠙⣳⣶⠞⠋⠉⠀⣀⡶⠾⠋⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣎⠌⢳⣄⠀⠀⢹⣆⠀⠀⠀⠀⠀⣼⠃⣿⠀⠀⠀⠀⠀⠀⠀⣠⠟⠁⠀⠀⠀⠀⠀⣠⣴⡿⠛⠁⢀⣤⠶⠛⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣦⡀⠙⣧⡀⠀⢻⡄⠀⠀⠀⣸⠇⠀⣿⠀⠀⠀⠀⠀⢠⡾⠃⠀⠀⠀⢀⣤⠾⣫⡿⢋⣀⡴⠞⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣆⠈⠻⣆⠈⣷⠀⠀⣰⡏⠀⠀⢻⠀⠀⠀⢀⣴⠏⠀⠀⣀⣴⠞⠋⣠⣾⣿⠾⠛⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢷⣄⠘⢷⡼⣇⢀⡟⠀⠀⠀⢸⠀⠀⣠⠟⠁⣠⡴⠞⠉⢀⣠⡾⠟⠋
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣦⡀⠹⣿⡾⠁⠀⠀⠀⢸⣀⣾⣣⠶⠛⠁⣀⣤⠾⠋⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣄⠈⢿⡀⠀⠀⢀⣼⠟⠋⢀⣠⠴⠛⠉
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠷⣜⣧⠀⣠⠟⣁⣴⠞⠋⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣾⠿⠛⠉
*/

/// @notice Implements EIP-2535 Diamond proxy pattern, allowing dynamic addition, replacement, and removal of facets
/// @author David Dada <daveproxy80@gmail.com> (https://github.com/dadadave80)
/// @author Modified from Nick Mudge (https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/Diamond.sol)
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/Diamond.sol)
///
/// @dev Uses LibDiamond for facet management and LibOwnableRoles for ownership initialization
abstract contract Diamond is Proxy {
    /// @notice Initializes the Diamond proxy with the provided facets and initialization parameters
    /// @param _facetCuts Array of FacetCut structs defining facet addresses, corresponding function selectors, and actions (Add, Replace, Remove)
    /// @param _init Address of the initialization contract
    /// @param _calldata Calldata to be passed to the initialization contract
    constructor(FacetCut[] memory _facetCuts, address _init, bytes memory _calldata) payable {
        _diamondCut(_facetCuts, _init, _calldata);
    }

    /// @notice Receive function to accept plain Ether transfers
    /// @dev Allows contract to receive Ether without data
    receive() external payable virtual {}

    /// @notice Updates the facet addresses for the given selectors
    /// @param _facetCuts Array of FacetCut structs defining facet addresses, corresponding function selectors, and actions (Add, Replace, Remove)
    /// @param _init Address of the initialization contract
    /// @param _calldata Calldata to be passed to the initialization contract
    function _diamondCut(FacetCut[] memory _facetCuts, address _init, bytes memory _calldata) internal virtual {
        LibDiamond._diamondCut(_facetCuts, _init, _calldata);
    }

    /// @notice Returns the address of the facet for the given function selector
    /// @return facet_ Address of the facet for the given function selector
    function _implementation() internal view virtual override returns (address facet_) {
        facet_ = LibDiamond._diamondStorage().selectorToFacet[msg.sig];
        if (facet_ == address(0)) revert FunctionDoesNotExist(msg.sig);
    }

    /// @notice Hook to be called before fallback
    /// @dev Can be used to perform additional checks or modifications before delegating to the fallback function
    function _beforeFallback() internal virtual {}

    /// @notice Fallback function that delegates calls to the appropriate facet based on function selector
    /// @dev Reads the facet address from diamond storage and performs a delegatecall; reverts if selector is not found
    function _fallback() internal virtual override {
        _beforeFallback();
        super._fallback();
    }
}
