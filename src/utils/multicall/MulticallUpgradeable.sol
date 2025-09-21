// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ContextUpgradeable} from "@diamond/utils/context/ContextUpgradeable.sol";
import {Initializable} from "@diamond/utils/initializable/Initializable.sol";
import {LibMulticall} from "@diamond/utils/multicall/LibMulticall.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * Consider any assumption about calldata validation performed by the sender may be violated if it's not especially
 * careful about sending transactions invoking {multicall}. For example, a relay address that filters function
 * selectors won't filter calls nested within a {multicall} operation.
 *
 * NOTE: Since 5.0.1 and 4.9.4, this contract identifies non-canonical contexts (i.e. `msg.sender` is not {Context-_msgSender}).
 * If a non-canonical context is identified, the following self `delegatecall` appends the last bytes of `msg.data`
 * to the subcall. This makes it safe to use with {ERC2771Context}. Contexts that don't affect the resolution of
 * {Context-_msgSender} are not propagated to subcalls.
 */
abstract contract MulticallUpgradeable is Initializable, ContextUpgradeable {
    using LibMulticall for bytes[];

    function __Multicall_init() internal onlyInitializing {}

    function __Multicall_init_unchained() internal onlyInitializing {}

    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        return data._multicall();
    }
}
