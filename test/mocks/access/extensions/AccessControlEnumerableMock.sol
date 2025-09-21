// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibAccessControlEnumerable} from "@diamond/access/libraries/LibAccessControlEnumerable.sol";
import {AccessControlEnumerableImpl} from "@diamond/implementations/access/extensions/AccessControlEnumerableImpl.sol";

contract AccessControlEnumerableMock is AccessControlEnumerableImpl {
    function init(address admin) public override reinitializer(_getInitializedVersion() + 1) {
        __AccessControlEnumerable_init(admin);
        LibAccessControlEnumerable._registerInterface();
    }
}
