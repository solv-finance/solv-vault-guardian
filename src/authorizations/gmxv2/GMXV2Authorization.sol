// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

        // add GMXV2AuthorizationACL
        // address[] memory gmTokens = new address[](3);
        // gmTokens[0] = 0x47c031236e19d024b42f8AE6780E44A573170703; // GM: BTC-USDC
        // gmTokens[1] = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336; // GM: ETH-USDC
        // gmTokens[2] = 0xC25cEf6061Cf5dE5eb761b50E4743c1F5D7E5407; // GM: ARB-USDC

        // GMXV2AuthorizationACL.CollateralPair[] memory gmPairs = new GMXV2AuthorizationACL.CollateralPair[](3);
        // gmPairs[0] = GMXV2AuthorizationACL.CollateralPair({
        //     longCollateral: 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f, // WBTC
        //     shortCollateral: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 // USDC
        // });
        // gmPairs[1] = GMXV2AuthorizationACL.CollateralPair({
        //     longCollateral: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, // WETH
        //     shortCollateral: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 // USDC
        // });
        // gmPairs[2] = GMXV2AuthorizationACL.CollateralPair({
        //     longCollateral: 0x912CE59144191C1204E64559FE8253a0e49E6548, // ARB
        //     shortCollateral: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831 // USDC
        // });
        address acl = address(
            new GMXV2AuthorizationACL(address(this), safeAccount_, exchangeRouter_, 
            depositVault_, withdrawalVault_, gmTokens_, gmPairs_)
        );
        _setContractACL(exchangeRouter_, acl);
    }
}
