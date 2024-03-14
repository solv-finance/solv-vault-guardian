// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {SolvOpenEndFundAuthorizationACL} from "./SolvOpenEndFundAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract SolvOpenEndFundAuthorization is FunctionAuthorization {
    string public constant NAME = "SolvVaultGuardian_SolvOpenEndFundAuthorization";
    int256 public constant VERSION = 1;

    string public constant SHARE_FUNC_REPAY = "repay(uint256,address,uint256)";
    string public constant REDEMPTION_FUNC_REPAY = "repay(uint256,address,uint256)";

    constructor(
        address caller_,
        address openEndFundShare_,
        address openEndFundRedemption_,
        bytes32[] memory repayablePoolIds_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory openEndFundShareFuncs = new string[](1);
        openEndFundShareFuncs[0] = SHARE_FUNC_REPAY;
        _addContractFuncs(openEndFundShare_, openEndFundShareFuncs);

        string[] memory openEndFundRedemptionFuncs = new string[](1);
        openEndFundRedemptionFuncs[0] = REDEMPTION_FUNC_REPAY;
        _addContractFuncs(openEndFundRedemption_, openEndFundRedemptionFuncs);

        _setContractACL(openEndFundShare_, address(
            new SolvOpenEndFundAuthorizationACL(address(this), openEndFundShare_, repayablePoolIds_))
        );
        _setContractACL(openEndFundRedemption_, address(
            new SolvOpenEndFundAuthorizationACL(address(this), openEndFundRedemption_, repayablePoolIds_))
        );
    }
}
