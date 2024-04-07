// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.19;

import {BaseACL} from "../../common/BaseACL.sol";

contract SolvOpenEndFundSftAuthorizationACL is BaseACL {

    string public constant NAME = "SolvVaultGuard_SolvOpenFundSftAuthorizationACL";
    uint256 public constant VERSION = 1;

    constructor(address caller_, address safeAccount_) BaseACL(caller_) {
        safeAccount = safeAccount_;
    }

    function claimTo(address to, uint256 /* tokenId */, address /* currency */, uint256 /* claimValue */) external view {
        _checkValueZero();
        require(to == safeAccount, "SolvOpenEndFundSftAuthorizationACL: to not allowed");
    }

}
