// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {MerlinSwapLiquidityManagerAuthorizationACL} from "./MerlinSwapLiquidityManagerAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract MerlinSwapLiquidityManagerAuthorization is FunctionAuthorization {

    string public constant NAME = "SolvVaultGuardian_MerlinSwapLiquidityManagerAuthorization";
    uint256 public constant VERSION = 1;

    constructor(
        address caller_,
        address safeAccount_,
        address liquidityManager_,
        address[] memory tokenWhitelist_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory merlinSwapLiquidityManagerFuncs = new string[](8);
        merlinSwapLiquidityManagerFuncs[0] = "mint((address,address,address,uint24,int24,int24,uint128,uint128,uint128,uint128,uint256))";
        merlinSwapLiquidityManagerFuncs[1] = "addLiquidity((uint256,uint128,uint128,uint128,uint128,uint256))";
        merlinSwapLiquidityManagerFuncs[2] = "decLiquidity(uint256,uint128,uint256,uint256,uint256)";
        merlinSwapLiquidityManagerFuncs[3] = "collect(address,uint256,uint128,uint128)";
        merlinSwapLiquidityManagerFuncs[4] = "unwrapWETH9(uint256,address)";
        merlinSwapLiquidityManagerFuncs[5] = "sweepToken(address,uint256,address)";
        merlinSwapLiquidityManagerFuncs[6] = "refundETH()";
        merlinSwapLiquidityManagerFuncs[7] = "burn(uint256)";
        _addContractFuncs(liquidityManager_, merlinSwapLiquidityManagerFuncs);

        address acl = address(new MerlinSwapLiquidityManagerAuthorizationACL(address(this), safeAccount_, liquidityManager_, tokenWhitelist_));
        _setContractACL(liquidityManager_, acl);
    }
}
