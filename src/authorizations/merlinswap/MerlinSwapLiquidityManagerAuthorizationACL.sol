// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";
import {Path} from "../../libraries/Path.sol";
import {BytesLib} from "../../libraries/BytesLib.sol";
import "../../external/merlinSwap/ILiquidityManager.sol";

contract MerlinSwapLiquidityManagerAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Path for bytes;
    using BytesLib for bytes;

    string public constant NAME = "SolvVaultGuardian_MerlinSwapLiquidityManagerAuthorizationACL";
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
        require(token != address(0), "MerlinSwapLiquidityManagerACL: token cannot be the zero address");
        if (_tokenWhitelist.add(token)) {
            emit AddTokenWhitelist(token);
        }
    }

    function _checkToken(address token) internal view virtual returns (bool) {
        return _tokenWhitelist.contains(token);
    }

    function mint(ILiquidityManager.MintParam calldata params) external view virtual {
        require(_checkToken(params.tokenX), "MerlinSwapLiquidityManagerACL: tokenX not allowed");
        require(_checkToken(params.tokenY), "MerlinSwapLiquidityManagerACL: tokenY not allowed");
        require(params.miner == safeAccount, "MerlinSwapLiquidityManagerACL: recipient(miner) not allowed");

    }

    function addLiquidity(
        ILiquidityManager.AddLiquidityParam calldata addLiquidityParam
    ) external view virtual {}

    function decLiquidity(
        uint256 lid,
        uint128 liquidDelta,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256 deadline
    ) external view virtual {}

    function collect(
        address recipient,
        uint256 /* lid */,
        uint128 /* amountXLim */,
        uint128 /* amountYLim */
    ) external view virtual {
        require(recipient == safeAccount, "MerlinSwapLiquidityManagerACL: recipient not allowed");
    }


    function unwrapWETH9(uint256 /* minAmount */, address recipient) external view virtual {
        require(recipient == safeAccount, "MerlinSwapLiquidityManagerACL: recipient not allowed");
    }

    function sweepToken(
        address token,
        uint256 /** minAmount */,
        address recipient
    ) external view virtual {
        require(recipient == safeAccount, "MerlinSwapLiquidityManagerACL: recipient not allowed");
        require(_checkToken(token), "MerlinSwapLiquidityManagerACL: token not allowed");
    }

    function refundETH() external view virtual {}

    function burn(uint256 lid) external view virtual {}

}
