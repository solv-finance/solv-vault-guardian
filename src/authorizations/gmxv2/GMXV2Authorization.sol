// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {FunctionAuthorization} from "../../common/FunctionAuthorization.sol";
import {GMXV2AuthorizationACL} from "./GMXV2AuthorizationACL.sol";
import {Governable} from "../../utils/Governable.sol";

contract GMXV2Authorization is FunctionAuthorization {
    string public constant NAME = "SolvVaultGuard_GMXV2Authorization";
    uint256 public constant VERSION = 1;

    /**
     * On Arbitrum
     * gmxExchangeRouter: 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8
     * gmxDepositVault: 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55
     * gmxWithdrawalVault: 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55
     */
    constructor(
        address caller_,
        address safeAccount_,
        address exchangeRouter_,
        address depositVault_,
        address withdrawalVault_,
        address[] memory gmTokens_,
        GMXV2AuthorizationACL.CollateralPair[] memory gmPairs_

    ) FunctionAuthorization(caller_, Governable(caller_).governor()) {
        string[] memory gmxExchangeRouterFuncs = new string[](1);
        gmxExchangeRouterFuncs[0] = "multicall(bytes[])";
        _addContractFuncs(exchangeRouter_, gmxExchangeRouterFuncs);

        address acl = address(
            new GMXV2AuthorizationACL(address(this), safeAccount_, exchangeRouter_, 
            depositVault_, withdrawalVault_, gmTokens_, gmPairs_)
        );
        _setContractACL(exchangeRouter_, acl);
    }
}
