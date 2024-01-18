// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {GMXV1AuthorizationACL} from "./GMXV1AuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract GMXV1Authorization is FunctionAuthorization {

    string public constant NAME = "SolvVaultGuardian_GMXV1Authorization";
    uint256 public constant VERSION = 1;

    address public constant GMX_REWAED_ROUTER_V2 = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
    address public constant GMX_REWAED_ROUTER = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;

    string public constant ERC20_APPROVE_FUNC = "approve(address,uint256)";
    string public constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";

    constructor(address safeAccount_, address safeMultiSendContract_, address caller_)
        FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor())
    {
        string[] memory glpRewardRouterV2Funcs = new string[](3);
        glpRewardRouterV2Funcs[0] = "handleRewards(bool,bool,bool,bool,bool,bool,bool)";
        glpRewardRouterV2Funcs[1] = "claim()";
        glpRewardRouterV2Funcs[2] = "compound()";

        _addContractFuncs(GMX_REWAED_ROUTER, glpRewardRouterV2Funcs);

        string[] memory glpRewardRouterFuncs = new string[](4);
        glpRewardRouterFuncs[0] = "mintAndStakeGlp(address,uint256,uint256,uint256)";
        glpRewardRouterFuncs[1] = "unstakeAndRedeemGlp(address,uint256,uint256,address)";
        glpRewardRouterFuncs[2] = "mintAndStakeGlpETH(uint256,uint256)";
        glpRewardRouterFuncs[3] = "unstakeAndRedeemGlpETH(uint256,uint256,address)";

        _addContractFuncs(GMX_REWAED_ROUTER_V2, glpRewardRouterFuncs);

        string[] memory tokensFuncs = new string[](2);
        tokensFuncs[0] = ERC20_APPROVE_FUNC;
        tokensFuncs[1] = ERC20_TRANSFER_FUNC;

        address[] memory tokens = new address[](10);
        tokens[0] = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //WETH
        tokens[1] = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f; //WBTC
        tokens[2] = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4; //LINK
        tokens[3] = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0; //UNI
        tokens[4] = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; //USDC
        tokens[5] = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; //USDC
        tokens[6] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; //DAI
        tokens[7] = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT
        tokens[8] = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F; //FRAX
        tokens[9] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; //ETH
        for (uint256 i = 0; i < tokens.length; i++) {
            _addContractFuncs(tokens[i], tokensFuncs);
        }

        address acl = address(new GMXV1AuthorizationACL(address(this), safeAccount_, tokens));
        _setContractACL(GMX_REWAED_ROUTER_V2, acl);
    }
}
