// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DeployDiamond} from "@diamond-script/DeployDiamond.s.sol";
import {GetSelectors} from "@diamond-test/helpers/GetSelectors.sol";
import {DiamondCutFacet} from "@diamond/implementations/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/implementations/DiamondLoupeFacet.sol";
import {OwnableImpl} from "@diamond/implementations/access/OwnableImpl.sol";
import {DiamondInit} from "@diamond/initializers/DiamondInit.sol";

abstract contract DiamondBase is GetSelectors {
    address public diamond;
    address public diamondInit;
    DiamondCutFacet public diamondCut;
    DiamondLoupeFacet public diamondLoupe;
    OwnableImpl public ownable;

    address[] public facetAddresses;

    string[3] public facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnableImpl"];

    address public owner = address(this);
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public virtual {
        DeployDiamond deployDiamond = new DeployDiamond();

        (diamond, diamondInit) = deployDiamond.run();
        diamondCut = DiamondCutFacet(diamond);
        diamondLoupe = DiamondLoupeFacet(diamond);
        ownable = OwnableImpl(diamond);

        facetAddresses = diamondLoupe.facetAddresses();
    }
}
