// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {SolvMasterFundAuthorizationACL} from "./SolvMasterFundAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract SolvMasterFundAuthorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_MasterFundAuthorization";
    uint256 public constant VERSION = 1;

    constructor(
        address caller_,
        address safeAccount_,
        address openFundMarket_,
        bytes32[] memory poolIdWhitelist_
    ) 
        FunctionAuthorization(caller_, Governable(caller_).governor()) 
    {
        string[] memory openFundMarketFuncs = new string[](3);
        openFundMarketFuncs[0] = "subscribe(bytes32,uint256,uint256,uint64)";
        openFundMarketFuncs[1] = "requestRedeem(bytes32,uint256,uint256,uint256)";
        openFundMarketFuncs[2] = "revokeRedeem(bytes32,uint256)";
        _addContractFuncs(openFundMarket_, openFundMarketFuncs);

        address acl = address(
            new SolvMasterFundAuthorizationACL(
                address(this), safeAccount_, Governable(caller_).governor(), openFundMarket_, poolIdWhitelist_
            )
        );
        _setContractACL(openFundMarket_, acl);
    }
}
