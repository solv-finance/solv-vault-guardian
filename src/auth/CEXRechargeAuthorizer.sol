// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {TransferAuthorizer} from "../common/TransferAuthorizer.sol";

contract CEXRechargeAuthorizer is TransferAuthorizer {
	constructor(address safeguard_) TransferAuthorizer(safeguard_) {}
}