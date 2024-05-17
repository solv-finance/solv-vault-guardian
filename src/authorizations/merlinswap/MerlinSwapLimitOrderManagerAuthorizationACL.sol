// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";
import {Path} from "../../libraries/Path.sol";
import {BytesLib} from "../../libraries/BytesLib.sol";
import "../../external/merlinSwap/ILimitOrderManager.sol";

contract MerlinSwapLimitOrderManagerAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Path for bytes;
    using BytesLib for bytes;

    string public constant NAME = "SolvVaultGuardian_MerlinSwapLimitOrderManagerAuthorizationACL";
    uint256 public constant VERSION = 1;

    address public limitOrderManager;

    EnumerableSet.AddressSet internal _tokenWhitelist;

    event AddTokenWhitelist(address indexed token);

    constructor(
        address caller_,
        address safeAccount_,
        address limitOrderManager_,
        address[] memory tokenWhitelist_
    ) BaseACL(caller_) {
        safeAccount = safeAccount_;
        limitOrderManager = limitOrderManager_;
        for (uint256 i = 0; i < tokenWhitelist_.length; i++) {
            _addTokenWhitelist(tokenWhitelist_[i]);
        }
    }

    function _addTokenWhitelist(address token) internal {
        require(token != address(0), "MerlinSwapLimitOrderManagerACL: token cannot be the zero address");
        if (_tokenWhitelist.add(token)) {
            emit AddTokenWhitelist(token);
        }
    }

    function _checkToken(address token) internal view virtual returns (bool) {
        return _tokenWhitelist.contains(token);
    }

    function newLimOrder(uint256 /* idx */, ILimitOrderManager.AddLimOrderParam calldata addLimitOrderParam) external view virtual {
        require(_checkToken(addLimitOrderParam.tokenX), "MerlinSwapLimitOrderManagerACL: tokenX not allowed");
        require(_checkToken(addLimitOrderParam.tokenY), "MerlinSwapLimitOrderManagerACL: tokenY not allowed");
    }


    function collectLimOrder(address recipient, uint256 /* orderIdx */, uint128 /* collectDec */, uint128 /* collectEarn */) external view virtual {
        require(recipient == safeAccount, "MerlinSwapLimitOrderManagerACL: recipient not allowed");
    }


    function decLimOrder(uint256 orderIdx, uint128 amount, uint256 deadline) external view virtual {
    }

}
