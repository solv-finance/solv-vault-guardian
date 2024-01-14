// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {SolvOpenEndFundAuthorizationACL} from "./SolvOpenEndFundAuthorizationACL.sol";
import {Governable} from "../utils/Governable.sol";

contract SolvOpenEndFundAuthorization is FunctionAuthorization {
    string public constant NAME = "SolvVaultGuard_SolvOpenEndFundAuthorization";
    int256 public constant VERSION = 1;

    string public constant MARKET_FUNC_SET_REDEEM_NAV = "setRedeemNav(bytes32,uint256,uint256,uint256)";
    string public constant MARKET_FUNC_UPDATE_FUNDRAISING_END_TIME = "updateFundraisingEndTime(bytes32,uint64)";

    string public constant SHARE_FUNC_REPAY = "repay(uint256,address,uint256)";
    string public constant SHARE_FUNC_REPAY_WITH_BALANCE = "repayWithBalance(uint256,address,uint256)";

    string public constant REDEMPTION_FUNC_REPAY = "repay(uint256,address,uint256)";
    string public constant REDEMPTION_FUNC_REPAY_WITH_BALANCE = "repayWithBalance(uint256,address,uint256)";

    constructor(
        address safeMultiSendContract_,
        address caller_,
        address openEndFundMarket_,
        address openEndFundShare_,
        address openEndFundRedemption_,
        bytes32[] memory repayablePoolIds_
    ) FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor()) {
        string[] memory openEndFundMarketFuncs = new string[](2);
        openEndFundMarketFuncs[0] = MARKET_FUNC_SET_REDEEM_NAV;
        openEndFundMarketFuncs[1] = MARKET_FUNC_UPDATE_FUNDRAISING_END_TIME;
        _addContractFuncs(openEndFundMarket_, openEndFundMarketFuncs);

        string[] memory openEndFundShareFuncs = new string[](2);
        openEndFundShareFuncs[0] = SHARE_FUNC_REPAY;
        openEndFundShareFuncs[1] = SHARE_FUNC_REPAY_WITH_BALANCE;
        _addContractFuncs(openEndFundShare_, openEndFundShareFuncs);

        string[] memory openEndFundRedemptionFuncs = new string[](2);
        openEndFundRedemptionFuncs[0] = REDEMPTION_FUNC_REPAY;
        openEndFundRedemptionFuncs[1] = REDEMPTION_FUNC_REPAY_WITH_BALANCE;
        _addContractFuncs(openEndFundRedemption_, openEndFundRedemptionFuncs);

        address acl = address(new SolvOpenEndFundAuthorizationACL(caller_, openEndFundRedemption_, repayablePoolIds_));
        _setContractACL(openEndFundShare_, acl);
    }
}
