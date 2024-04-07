// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC3525Authorization} from "../ERC3525Authorization.sol";
import {SolvOpenEndFundSftAuthorizationACL} from "./SolvOpenEndFundSftAuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract SolvOpenEndFundSftAuthorization is ERC3525Authorization {

    constructor(
        address caller_,
        address safeAccount_,
        address openEndFundSft_,
        TokenSpenders[] memory tokenSpenders_
    ) 
        ERC3525Authorization(caller_, tokenSpenders_) 
    {
        string[] memory claimFuncs = new string[](1);
        claimFuncs[0] = "claimTo(address,uint256,address,uint256)";
        _addContractFuncs(openEndFundSft_, claimFuncs);

        _setContractACL(
            openEndFundSft_, 
            address(new SolvOpenEndFundSftAuthorizationACL(address(this), safeAccount_))
        );
    }
}
