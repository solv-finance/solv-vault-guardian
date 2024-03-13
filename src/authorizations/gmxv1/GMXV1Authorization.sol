// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {GMXV1AuthorizationACL} from "./GMXV1AuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract GMXV1Authorization is FunctionAuthorization {
    string public constant NAME = "SolvVaultGuardian_GMXV1Authorization";
    uint256 public constant VERSION = 1;

    constructor(
        address caller_,
        address safeAccount_, 
        address gmxRewardRouter,
        address gmxRewardRouterV2,
        address[] memory allowTokens_
    )
        FunctionAuthorization(caller_, Governable(caller_).governor())
    {
        string[] memory glpRewardRouterFuncs = new string[](3);
        glpRewardRouterFuncs[0] = "handleRewards(bool,bool,bool,bool,bool,bool,bool)";
        glpRewardRouterFuncs[1] = "claim()";
        glpRewardRouterFuncs[2] = "compound()";
        _addContractFuncs(gmxRewardRouter, glpRewardRouterFuncs);

        string[] memory glpRewardRouterV2Funcs = new string[](4);
        glpRewardRouterV2Funcs[0] = "mintAndStakeGlp(address,uint256,uint256,uint256)";
        glpRewardRouterV2Funcs[1] = "unstakeAndRedeemGlp(address,uint256,uint256,address)";
        glpRewardRouterV2Funcs[2] = "mintAndStakeGlpETH(uint256,uint256)";
        glpRewardRouterV2Funcs[3] = "unstakeAndRedeemGlpETH(uint256,uint256,address)";
        _addContractFuncs(gmxRewardRouterV2, glpRewardRouterV2Funcs);

        address acl = address(new GMXV1AuthorizationACL(address(this), safeAccount_, allowTokens_));
        _setContractACL(gmxRewardRouterV2, acl);
    }
}
