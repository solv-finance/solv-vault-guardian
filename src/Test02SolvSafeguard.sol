// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SolvSafeguardRoot } from "./common/SolvSafeguardRoot.sol";
import { CoboArgusAdminGuard } from "./strategies/guards/CoboArgusAdminGuard.sol";
import { OpenEndFundSettlementGuard } from "./strategies/guards/OpenEndFundSettlementGuard.sol";
import { TransferGuard } from "./strategies/guards/TransferGuard.sol";
import { GMXV2OpenEndFundGuard } from "./strategies/guards/GMXV2OpenEndFundGuard.sol";

contract Test02SolvSafeguard is SolvSafeguardRoot {
	string public constant NAME = "Test02SolvSafeguard";
    uint256 public constant VERSION = 1;

	constructor(
		address safeAccount_, address governor_,
		address coboArgusAdminGuard_, address openEndFundSettlementGuard_, address gmxV2OpenEndFundGuard_
	) SolvSafeguardRoot(safeAccount_, governor_) {
		__GMXV2SolvSafeguard_init(coboArgusAdminGuard_, openEndFundSettlementGuard_, gmxV2OpenEndFundGuard_);
	}

	function __GMXV2SolvSafeguard_init(
		address coboArgusAdminGuard_, address openEndFundSettlementGuard_, address gmxV2OpenEndFundGuard_
	) internal {
		// Cobo Argus Admin Guard
		bytes32 coboArgusAdminCluster = bytes32(keccak256("CoboArgusAdminGuards"));
		address[] memory coboArgusAdminGuards = new address[](1);
		coboArgusAdminGuards[0] = coboArgusAdminGuard_;
		_addSolvGuards(coboArgusAdminCluster, coboArgusAdminGuards);

		// OpenEndFundSettlementGuard
		bytes32 openEndFundSettlementCluster = bytes32(keccak256("OpenEndFundSettlementGuards"));
		address[] memory openEndFundSettlementGuards = new address[](1);
		openEndFundSettlementGuards[0] = openEndFundSettlementGuard_;
		_addSolvGuards(openEndFundSettlementCluster, openEndFundSettlementGuards);

		// gmx v2 open end fund
		bytes32 gmxV2OpenEndFundCluster = bytes32(keccak256("GmxV2OpenEndFund"));
		address[] memory gmxV2OpenEndFundGuards = new address[](1);
		gmxV2OpenEndFundGuards[0] = gmxV2OpenEndFundGuard_;
		_addSolvGuards(gmxV2OpenEndFundCluster, gmxV2OpenEndFundGuards);
	}
}