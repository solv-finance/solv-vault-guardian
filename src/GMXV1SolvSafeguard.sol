// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SolvSafeguardRootGuard} from "./common/SolvSafeguardRootGuard.sol";
import {TransferGuard} from "./guards/TransferGuard.sol";
import {GMXV1OpenEndFundGuard} from "./guards/GMXV1OpenEndFundGuard.sol";

contract GMXV1SolvSafeguard is SolvSafeguardRootGuard {
	constructor(address safeAccount_, address erc20_, address cexRechargeAdress_, address openEndFundMarket_, 
			address openEndFundShare_, address openEndFundRedemption_) SolvSafeguardRootGuard(safeAccount_) {

		//cex recharge address
		TransferGuard.TokenReceiver[] memory tokenReceivers = new TransferGuard.TokenReceiver[](1);
		tokenReceivers[0] = TransferGuard.TokenReceiver({
			token: erc20_,
			receiver: cexRechargeAdress_
		});
		address[] memory guards = new address[](2);
		guards[0] = address(new TransferGuard(tokenReceivers));
		guards[1] = address(new GMXV1OpenEndFundGuard(openEndFundMarket_, openEndFundShare_, openEndFundRedemption_));

		_setGuards(guards);
	}
}