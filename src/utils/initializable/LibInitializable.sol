// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {INITIALIZABLE_STORAGE_SLOT, InitializableStorage} from "@diamond/utils/initializable/InitializableStorage.sol";

/**
 * @dev The contract is already initialized.
 */
error InvalidInitialization();

/**
 * @dev The contract is not initializing.
 */
error NotInitializing();

/**
 * @dev Triggered when the contract has been initialized or reinitialized.
 */
event Initialized(uint64 version);

library LibInitializable {
    function _initializableStorage() internal pure returns (InitializableStorage storage ins_) {
        assembly {
            ins_.slot := INITIALIZABLE_STORAGE_SLOT
        }
    }

    function _beforeInitializer(InitializableStorage storage _ins) internal returns (bool isTopLevelCall_) {
        // Cache values to avoid duplicated sloads
        isTopLevelCall_ = !_ins.initializing;
        uint64 initialized = _ins.initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reinitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall_;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        _ins.initialized = 1;
        if (isTopLevelCall_) {
            _ins.initializing = true;
        }
    }

    function _afterInitializer(InitializableStorage storage _ins, bool _isTopLevelCall) internal {
        if (_isTopLevelCall) {
            _ins.initializing = false;
            emit Initialized(1);
        }
    }

    function _beforeReinitializer(InitializableStorage storage _ins, uint64 _version) internal {
        if (_ins.initializing || _ins.initialized >= _version) {
            revert InvalidInitialization();
        }
        _ins.initialized = _version;
        _ins.initializing = true;
    }

    function _afterReinitializer(InitializableStorage storage _ins, uint64 _version) internal {
        _ins.initializing = false;
        emit Initialized(_version);
    }

    function _checkInitializing() internal view {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    function _disableInitializers() internal {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage ins = _initializableStorage();

        if (ins.initializing) {
            revert InvalidInitialization();
        }
        if (ins.initialized != type(uint64).max) {
            ins.initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    function _getInitializedVersion() internal view returns (uint64) {
        return _initializableStorage().initialized;
    }

    function _isInitializing() internal view returns (bool) {
        return _initializableStorage().initializing;
    }

    function _initializableStorageSlot() internal pure returns (bytes32) {
        return INITIALIZABLE_STORAGE_SLOT;
    }
}
