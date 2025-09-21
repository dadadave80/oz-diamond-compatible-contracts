// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Diamond, FacetCut} from "@diamond/proxy/diamond/Diamond.sol";

contract MockDiamond is Diamond {
    constructor(FacetCut[] memory _facetCuts, address _init, bytes memory _calldata)
        payable
        Diamond(_facetCuts, _init, _calldata)
    {}
}
