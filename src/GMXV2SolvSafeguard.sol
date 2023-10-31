// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { SolvSafeguardRoot } from "./common/SolvSafeguardRoot.sol";
import { CoboArgusAdminGuard } from "./strategies/guards/CoboArgusAdminGuard.sol";
import { OpenEndFundSettlementGuard } from "./strategies/guards/OpenEndFundSettlementGuard.sol";
import { TransferGuard } from "./strategies/guards/TransferGuard.sol";
import { GMXV2OpenEndFundGuard } from "./strategies/guards/GMXV2OpenEndFundGuard.sol";

contract GMXV2SolvSafeguard is SolvSafeguardRoot {
	string public constant NAME = "GMXV2SolvSafeguard";
    uint256 public constant VERSION = 1;

	constructor(
		address safeAccount_, address erc20_, address cexRechargeAdress_, 
		address openEndFundMarket_, address openEndFundShare_, address openEndFundRedemption_
	) SolvSafeguardRoot(safeAccount_) {
		__GMXV2SolvSafeguard_init(erc20_, cexRechargeAdress_, openEndFundMarket_, openEndFundShare_, openEndFundRedemption_);
	}

	function __GMXV2SolvSafeguard_init(
		address erc20_, address cexRechargeAdress_, address openEndFundMarket_, 
		address openEndFundShare_, address openEndFundRedemption_
	) internal {
		// Cobo Argus Admin Guard
		bytes32 coboArgusAdminCluster = bytes32(keccak256("CoboArgusAdminGuards"));
		CoboArgusAdminGuard coboArgusAdminGuard = new CoboArgusAdminGuard();
		address[] memory coboArgusAdminGuards = new address[](1);
		coboArgusAdminGuards[0] = address(coboArgusAdminGuard);
		_addSolvGuards(coboArgusAdminCluster, coboArgusAdminGuards);

		// cex recharge address
		bytes32 transferCluster = bytes32(keccak256("TransferGuards"));
		TransferGuard.TokenReceiver[] memory tokenReceivers = new TransferGuard.TokenReceiver[](1);
		tokenReceivers[0] = TransferGuard.TokenReceiver({
			token: erc20_,
			receiver: cexRechargeAdress_
		});
		TransferGuard transferGuard = new TransferGuard(tokenReceivers);
		address[] memory transferGuards = new address[](1);
		transferGuards[0] = address(transferGuard);
		_addSolvGuards(transferCluster, transferGuards);

		// OpenEndFundSettlementGuard
		bytes32 openEndFundSettlementCluster = bytes32(keccak256("OpenEndFundSettlementGuards"));
		OpenEndFundSettlementGuard openEndFundSettlementGuard = new OpenEndFundSettlementGuard(
			openEndFundMarket_, openEndFundShare_, openEndFundRedemption_
		);
		address[] memory openEndFundSettlementGuards = new address[](1);
		openEndFundSettlementGuards[0] = address(openEndFundSettlementGuard);
		_addSolvGuards(openEndFundSettlementCluster, openEndFundSettlementGuards);

		// gmx v2 open end fund
		bytes32 gmxV2OpenEndFundCluster = bytes32(keccak256("GmxV2OpenEndFund"));
		GMXV2OpenEndFundGuard gmxV2OpenEndFundGuard = new GMXV2OpenEndFundGuard(safeAccount);
		address[] memory gmxV2OpenEndFundGuards = new address[](1);
		gmxV2OpenEndFundGuards[0] = address(gmxV2OpenEndFundGuard);
		_addSolvGuards(gmxV2OpenEndFundCluster, gmxV2OpenEndFundGuards);
	}


}