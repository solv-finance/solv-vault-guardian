// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {FoFNavManagerAuthorizationACL} from "./FoFNavManagerAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract FoFNavManagerAuthorization is FunctionAuthorization {
    string public constant NAME = "SolvVaultGuardian_FoFNavManagerAuthorization";
    int256 public constant VERSION = 1;

    // setSubscribeNav(bytes32 poolId, uint256 time, uint256 nav)
    string public constant MARKET_SET_SUBSCRIBE_NAV_FUNC = "setSubscribeNav(bytes32,uint256,uint256)";
    // setRedeemNav(bytes32 poolId, uint256 redeemSlot, uint256 nav, uint256 currencyBalance)
    string public constant MARKET_SET_REDEEM_NAV_FUNC = "setRedeemNav(bytes32,uint256,uint256,uint256)";

    constructor(
        address caller_,
        address openFundMarket_,
        bytes32[] memory authorizedPoolIds_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory openFundMarketFuncs = new string[](2);
        openFundMarketFuncs[0] = MARKET_SET_SUBSCRIBE_NAV_FUNC;
        openFundMarketFuncs[1] = MARKET_SET_REDEEM_NAV_FUNC;
        _addContractFuncs(openFundMarket_, openFundMarketFuncs);

        _setContractACL(openFundMarket_, address(
            new FoFNavManagerAuthorizationACL(address(this), openFundMarket_, authorizedPoolIds_))
        );
    }
}
