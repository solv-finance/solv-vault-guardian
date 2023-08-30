// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Errors} from "./Errors.sol";
import {TransactionData} from "./Types.sol";

abstract contract BaseAuthorizer {
	address public immutable safeguard;
	fallback() external {
		// We don't revert on fallback to avoid issues in case of a Safe upgrade
		// E.g. The expected check method might change and then the Safe would be locked.
	}

	modifier onlySafeguard {
		require(msg.sender == safeguard, Errors.CALLER_IS_NOT_SAFEGUARD);
		_;
	}

	constructor(address safeguard_) {
		safeguard = safeguard_;
	}

	function checkTransaction( TransactionData calldata txData ) external virtual onlySafeguard returns (bool) {
		return _checkTransaction(txData);
	} 

	function _checkTransaction( TransactionData calldata txData ) internal virtual view returns (bool);
}