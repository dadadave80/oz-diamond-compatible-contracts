// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {Diamond} from "@diamond/Diamond.sol";
import {HelperContract} from "@diamond-test/helpers/HelperContract.sol";
import {AddMyShinyFacetHelper} from "@diamond-test/helpers/AddMyShinyFacetHelper.sol";
import {MyShinyFacet} from "@diamond/facets/MyShinyFacet.sol";
import {FacetCutAction, FacetCut} from "@diamond/libraries/types/DiamondTypes.sol";
import {IDiamondCut} from "@diamond/interfaces/IDiamondCut.sol";

contract AddMyShinyFacet is Script, AddMyShinyFacetHelper {
    function run(Diamond diamond) external returns (MyShinyFacet myShinyFacet_) {
        vm.startBroadcast();

        myShinyFacet_ = _addMyShinyFacet(diamond);

        vm.stopBroadcast();
    }
}

contract SetAndGetShine is Script {
    MyShinyFacet myShinyFacet;

    function run(address diamond) public returns (string memory, uint8) {
        // Deploy MyShinyFacet contract
        vm.startBroadcast();

        // Call diamondCut on the diamond address
        bytes memory call = abi.encodeWithSelector(MyShinyFacet.setShine.selector, 50);
        (bool success,) = diamond.call(call);
        if (!success) revert("");

        bytes memory call1 = abi.encodeWithSelector(MyShinyFacet.getShine.selector);
        (bool success1, bytes memory ret) = diamond.call(call1);
        if (!success1) revert("");

        vm.stopBroadcast();
        return (string(ret), uint8(ret.length));
    }
}
