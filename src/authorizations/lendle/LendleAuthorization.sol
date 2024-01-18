// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {LendleAuthorizationACL} from "./LendleAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract LendleAuthorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_LendleAuthorization";
    uint256 public constant VERSION = 1;

    /**
     * On Mantle
     * Lendle LendingPool: 0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3
     */
    constructor(
        address safeMultiSendContract_,
        address caller_,
        address safeAccount_,
        address lendingPool_,
        address[] memory assetWhitelist_
    ) 
        FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor()) 
    {
        string[] memory lendingPoolFuncs = new string[](5);
        lendingPoolFuncs[0] = "deposit(address,uint256,address,uint16)";
        lendingPoolFuncs[1] = "withdraw(address,uint256,address)";
        lendingPoolFuncs[2] = "borrow(address,uint256,uint256,uint16,address)";
        lendingPoolFuncs[3] = "withdraw(address,uint256,uint256,address)";
        lendingPoolFuncs[4] = "swapBorrowRateMode(address,uint256)";
        _addContractFuncs(lendingPool_, lendingPoolFuncs);

        address acl = address(new LendleAuthorizationACL(address(this), safeAccount_, lendingPool_, assetWhitelist_));
        _setContractACL(lendingPool_, acl);
    }
}
