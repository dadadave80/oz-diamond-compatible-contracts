// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AddressAndCalldataLengthDoNotMatch} from "@diamond/proxy/diamond/libraries/DiamondErrors.sol";
import {LibDiamond} from "@diamond/proxy/diamond/libraries/LibDiamond.sol";
import {Initializable} from "@diamond/utils/initializable/Initializable.sol";
import {InitializableStorage, LibInitializable} from "@diamond/utils/initializable/LibInitializable.sol";

/// @notice Executes multiple initialization calls in sequence during a diamond upgrade
/// @author David Dada
/// @author Modified from Timo (https://github.com/FydeTreasury/Diamond-Foundry/blob/main/src/upgradeInitializers/DiamondMultiInit.sol)
///
/// @dev Useful when a diamond cut requires initializing several facets at once
contract DiamondInit is Initializable {
    /// @notice Performs multiple initialization calls to provided addresses with corresponding calldata
    /// @dev Reverts if `_addresses.length != _calldata.length`. Each address is called via delegatecall using LibDiamond._initializeDiamondCut.
    /// @param _addresses The list of initializer contract addresses
    /// @param _calldata The list of encoded function calls for each initializer
    function init(address[] calldata _addresses, bytes[] calldata _calldata) external {
        uint256 addressesLength = _addresses.length;
        if (addressesLength != _calldata.length) revert AddressAndCalldataLengthDoNotMatch();
        for (uint256 i; i < addressesLength; ++i) {
            LibDiamond._initializeDiamondCut(_addresses[i], _calldata[i]);
        }
    }

    /// @notice Performs multiple initialization calls to provided addresses with corresponding calldata
    /// @dev Reverts if `_addresses.length != _calldata.length`. Each address is called via delegatecall using LibDiamond._initializeDiamondCut.
    /// @param _addresses The list of initializer contract addresses
    /// @param _calldata The list of encoded function calls for each initializer
    function reinit(address[] calldata _addresses, bytes[] calldata _calldata)
        external
        reinitializer(_getInitializedVersion() + 1)
    {
        uint256 addressesLength = _addresses.length;
        if (addressesLength != _calldata.length) revert AddressAndCalldataLengthDoNotMatch();
        for (uint256 i; i < addressesLength; ++i) {
            LibDiamond._initializeDiamondCut(_addresses[i], _calldata[i]);
        }
    }
}
