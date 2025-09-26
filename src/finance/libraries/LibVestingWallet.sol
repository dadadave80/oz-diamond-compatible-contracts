// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibOwnable} from "@diamond/access/libraries/LibOwnable.sol";
import {LibContext} from "@diamond/utils/context/LibContext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @dev Emitted when native tokens are released.
event EtherReleased(uint256 amount);

/// @dev Emitted when tokens are released.
event ERC20Released(address indexed token, uint256 amount);

// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.VestingWallet")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant VESTING_WALLET_STORAGE_SLOT = 0xa1eac494560f7591e4da38ed031587f09556afdfc4399dd2e205b935fdfa3900;

/// @custom:storage-location erc7201:openzeppelin.storage.VestingWallet
struct VestingWalletStorage {
    uint256 released;
    mapping(address token => uint256) erc20Released;
    uint64 start;
    uint64 duration;
}

library LibVestingWallet {
    function _vestingWalletStorage() internal pure returns (VestingWalletStorage storage vws_) {
        assembly {
            vws_.slot := VESTING_WALLET_STORAGE_SLOT
        }
    }

    function _init(uint64 _startTimestamp, uint64 _durationSeconds) internal {
        VestingWalletStorage storage vws = _vestingWalletStorage();
        vws.start = _startTimestamp;
        vws.duration = _durationSeconds;
    }

    function _start() internal view returns (uint256) {
        return _vestingWalletStorage().start;
    }

    function _duration() internal view returns (uint256) {
        return _vestingWalletStorage().duration;
    }

    function _end() internal view returns (uint256) {
        return _start() + _duration();
    }

    function _released() internal view returns (uint256) {
        return _vestingWalletStorage().released;
    }

    function _released(address _token) internal view returns (uint256) {
        return _vestingWalletStorage().erc20Released[_token];
    }

    function _release(uint256 _amount) internal {
        emit EtherReleased(_amount);
        Address.sendValue(payable(LibOwnable._owner()), _amount);
    }

    function _release(address _token, uint256 _amount) internal {
        emit ERC20Released(_token, _amount);
        SafeERC20.safeTransfer(IERC20(_token), LibOwnable._owner(), _amount);
    }
}
