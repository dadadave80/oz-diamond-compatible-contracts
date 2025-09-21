// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2StepImpl} from "@diamond/implementations/access/Ownable2StepImpl.sol";

contract Ownable2StepMock is Ownable2StepImpl {
    function _internal_transferOwnership(address newOwner) external {
        _transferOwnership(newOwner);
    }
}
