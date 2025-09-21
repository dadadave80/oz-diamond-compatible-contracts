// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library LibMulticall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function _multicall(bytes[] calldata _data) internal returns (bytes[] memory results_) {
        bytes memory context = msg.sender == LibContext._msgSender()
            ? new bytes(0)
            : msg.data[msg.data.length - LibContext._contextSuffixLength():];

        results_ = new bytes[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            results_[i] = Address.functionDelegateCall(address(this), bytes.concat(_data[i], context));
        }
    }
}
