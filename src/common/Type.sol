// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Type {
	struct TxData {
		address from; //msg.sender
		address to;
		uint256 value;
		bytes data; //calldata
	}

	struct CheckResult {
		bool success;
		string message;
	}
}