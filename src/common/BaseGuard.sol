// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

abstract contract BaseGuard {

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

	fallback() external {
		// We don't revert on fallback to avoid issues in case of a Safe upgrade
		// E.g. The expected check method might change and then the Safe would be locked.
	}

	function checkTransaction( TxData calldata txData ) external virtual returns (CheckResult memory) {
		return _checkTransaction(txData);
	} 

	function _checkTransaction( TxData calldata txData ) internal virtual returns (CheckResult memory);
}