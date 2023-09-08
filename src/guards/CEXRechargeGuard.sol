// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {TransferGuard} from "../common/TransferGuard.sol";


contract CEXRechargeGuard is TransferGuard {
	constructor(TokenReceiver[] memory receivers_) {
		_addTokenReceivers(receivers_);
	}
}