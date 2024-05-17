// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {MerlinSwapLimitOrderManagerAuthorizationACL} from "./MerlinSwapLimitOrderManagerAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract MerlinSwapLimitOrderManagerAuthorization is FunctionAuthorization {

    string public constant NAME = "SolvVaultGuardian_MerlinSwapLimitOrderManagerAuthorization";
    uint256 public constant VERSION = 1;

    constructor(
        address caller_,
        address safeAccount_,
        address limitOrderManager_,
        address[] memory tokenWhitelist_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory merlinSwapLimitOrderFuncs = new string[](3);
        merlinSwapLimitOrderFuncs[0] = "newLimOrder(uint256,(address,address,uint24,int24,uint128,bool,uint256))";
        merlinSwapLimitOrderFuncs[1] = "collectLimOrder(address,uint256,uint128,uint128)";
        merlinSwapLimitOrderFuncs[2] = "decLimOrder(uint256,uint128,uint256)";
        _addContractFuncs(limitOrderManager_, merlinSwapLimitOrderFuncs);

        address acl = address(new MerlinSwapLimitOrderManagerAuthorizationACL(address(this), safeAccount_, limitOrderManager_, tokenWhitelist_));
        _setContractACL(limitOrderManager_, acl);
    }
}
