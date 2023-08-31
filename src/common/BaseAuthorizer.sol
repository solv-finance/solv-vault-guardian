// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {TxData} from "./Types.sol";

abstract contract BaseAuthorizer {
	fallback() external {
		// We don't revert on fallback to avoid issues in case of a Safe upgrade
		// E.g. The expected check method might change and then the Safe would be locked.
	}

	function checkTransaction( TxData calldata txData ) external virtual returns (bool) {
		return _checkTransaction(txData);
	} 

	function _checkTransaction( TxData calldata txData ) internal virtual view returns (bool);
}