// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {MerlinSwapAuthorizationACL} from "./MerlinSwapAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract MerlinSwapAuthorization is FunctionAuthorization {

    string public constant NAME = "SolvVaultGuardian_MerlinSwapAuthorization";
    uint256 public constant VERSION = 1;

    constructor(
        address caller_,
        address safeAccount_,
        address merlinSwap_,
        address[] memory tokenWhitelist_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory merlinSwapFuncs = new string[](6);
        merlinSwapFuncs[0] = "swapDesire((bytes,address,uint128,uint256,uint256))";
        merlinSwapFuncs[1] = "swapAmount((bytes,address,uint128,uint256,uint256))";
        merlinSwapFuncs[2] = "swapY2X((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))";
        merlinSwapFuncs[3] = "swapY2XDesireX((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))";
        merlinSwapFuncs[4] = "swapX2Y((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))";
        merlinSwapFuncs[5] = "swapX2YDesireY((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))";
        _addContractFuncs(merlinSwap_, merlinSwapFuncs);

        address acl = address(new MerlinSwapAuthorizationACL(address(this), safeAccount_, merlinSwap_, tokenWhitelist_));
        _setContractACL(merlinSwap_, acl);
    }
}
