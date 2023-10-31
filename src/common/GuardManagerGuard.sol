// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { FunctionGuard } from "./FunctionGuard.sol";

contract GuardManagerGuard is FunctionGuard {
	string public constant SET_GUARD = "setGuard(address)";
	
	constructor(address safeAccount_) {
		string[] memory funcs = new string[](1);
		funcs[0] = SET_GUARD;
		_addContractFuncs(safeAccount_, funcs);
	}
}