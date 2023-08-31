// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

struct TxData {
	address from; //msg.sender
	address to;
	uint256 value;
	bytes data; //calldata
}