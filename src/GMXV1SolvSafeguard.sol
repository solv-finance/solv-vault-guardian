// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SolvSafeguardRoot} from "./common/SolvSafeguardRoot.sol";
import {TransferGuard} from "./strategies/TransferGuard.sol";
import {GMXV1OpenEndFundGuard} from "./strategies/GMXV1OpenEndFundGuard.sol";

contract GMXV1SolvSafeguard is SolvSafeguardRoot {
	bytes32 public constant NAME = "GMXV1SolvSafeguard";
    uint256 public constant VERSION = 1;

	address public transferGuard;
	address public gmxV1OpenEndFundGuard;

	function initialize(address safeAccount_, address erc20_, address cexRechargeAdress_, address openEndFundMarket_, 
			address openEndFundShare_, address openEndFundRedemption_) public initializer {
		__SolvSafeguardRootGuard_init(safeAccount_);
		__GMXV1SolvSafeguard_init(erc20_, cexRechargeAdress_, openEndFundMarket_, openEndFundShare_, openEndFundRedemption_);
	}
	function __GMXV1SolvSafeguard_init(address erc20_, address cexRechargeAdress_, address openEndFundMarket_, 
			address openEndFundShare_, address openEndFundRedemption_) internal {
		
		//cex recharge address
		TransferGuard.TokenReceiver[] memory tokenReceivers = new TransferGuard.TokenReceiver[](1);
		tokenReceivers[0] = TransferGuard.TokenReceiver({
			token: erc20_,
			receiver: cexRechargeAdress_
		});
		transferGuard = address(new TransferGuard(tokenReceivers));
		gmxV1OpenEndFundGuard = address(new GMXV1OpenEndFundGuard(openEndFundMarket_, openEndFundShare_, openEndFundRedemption_));
		address[] memory guards = new address[](2);
		guards[0] = transferGuard;
		guards[1] = gmxV1OpenEndFundGuard;

		_setGuards(guards);
	}
}