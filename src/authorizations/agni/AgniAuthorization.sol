// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {AgniAuthorizationACL} from "./AgniAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract AgniAuthorization is FunctionAuthorization {

    string public constant NAME = "SolvVaultGuardian_AgniAuthorization";
    uint256 public constant VERSION = 1;

    /**
     * On Mantle
     * Agni SwapRouter: 0x319B69888b0d11cEC22caA5034e25FfFBDc88421
     */
    constructor(
        address caller_,
        address safeAccount_,
        address agniSwapRouter_,
        address[] memory swapTokenWhitelist_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory agniSwapRouterFuncs = new string[](2);
        agniSwapRouterFuncs[0] = "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))";
        agniSwapRouterFuncs[1] = "exactInput((bytes,address,uint256,uint256,uint256))";
        _addContractFuncs(agniSwapRouter_, agniSwapRouterFuncs);

        address acl = address(new AgniAuthorizationACL(address(this), safeAccount_, agniSwapRouter_, swapTokenWhitelist_));
        _setContractACL(agniSwapRouter_, acl);
    }
}
