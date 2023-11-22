// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { FunctionGuard } from "../../common/FunctionGuard.sol";
import { ACLGuard } from "../../common/ACLGuard.sol";
import { GMXV2ACL } from "../acls/GMXV2ACL.sol";
import "forge-std/console.sol";

contract GMXV2OpenEndFundGuard is FunctionGuard, ACLGuard {
	using EnumerableSet for EnumerableSet.AddressSet;

	string public constant NAME = "GMXV2OpenEndFundGuard";
	uint256 public constant VERSION = 1;

    address public constant GMX_EXCHANGE_ROUTER = 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8;
    address public constant GMX_DEPOSIT_VAULT = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
    address public constant GMX_WITHDRAWAL_VAULT = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

	string public constant ERC20_APPROVE_FUNC = "approve(address,uint256)";
	string public constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";

	constructor(address safeAccount_) {
		string[] memory gmxExchangeRouterFuncs = new string[](1);
		gmxExchangeRouterFuncs[0] = "multicall(bytes[])";
		_addContractFuncs(GMX_EXCHANGE_ROUTER, gmxExchangeRouterFuncs);

		string[] memory tokensFuncs = new string[](2);
        tokensFuncs[0] = ERC20_APPROVE_FUNC;
        tokensFuncs[1] = ERC20_TRANSFER_FUNC;

		address[] memory tokens = new address[](4);
		tokens[0] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;  // ETH
		tokens[1] = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;  // USDC
		tokens[2] = 0x47c031236e19d024b42f8AE6780E44A573170703;  // GM: BTC-USDC
		tokens[3] = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;  // GM: ETH-USDC
        for (uint256 i = 0; i < tokens.length; i++) {
            _addContractFuncs(tokens[i], tokensFuncs);
            _addContractFuncs(tokens[i], tokensFuncs);
        }

		// add GMXV2ACL
		address[] memory gmTokens = new address[](2);
		gmTokens[0] = 0x47c031236e19d024b42f8AE6780E44A573170703;  // GM: BTC-USDC
		gmTokens[1] = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;  // GM: ETH-USDC

		GMXV2ACL.CollateralPair[] memory gmPairs = new GMXV2ACL.CollateralPair[](2);
		gmPairs[0] = GMXV2ACL.CollateralPair({ 
          longCollateral: 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,  // WBTC
          shortCollateral: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831  // USDC
        });
		gmPairs[1] = GMXV2ACL.CollateralPair({ 
          longCollateral: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,  // WBTC
          shortCollateral: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831  // USDC
        });
		address[] memory acls = new address[](1);
		acls[0] = address(new GMXV2ACL(address(this), safeAccount_, gmTokens, gmPairs));
		_addStrategyACLS(GMX_EXCHANGE_ROUTER, acls);
	}

	function _checkTransaction( TxData calldata txData ) internal virtual override returns (CheckResult memory result) {
		result = super._checkTransaction(txData);
		if (!result.success) {
			return result;
		}
		result = _executeACL(txData);
	}
}