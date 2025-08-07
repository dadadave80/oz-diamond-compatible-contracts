// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FacetCut} from "@diamond/libraries/types/DiamondStorage.sol";

//*//////////////////////////////////////////////////////////////////////////
//                             DIAMOND CUT EVENT
//////////////////////////////////////////////////////////////////////////*//

/// @notice Emitted when a diamond cut (facet add/replace/remove) is executed.
/// @dev Logged after executing `diamondCut` with its associated initializer.
/// @param diamondCut The array of facet cuts specifying facet addresses, actions, and function selectors.
/// @param init The address of the contract or facet to delegatecall for initialization.
/// @param data The calldata passed to the `init` address for initialization.
event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
