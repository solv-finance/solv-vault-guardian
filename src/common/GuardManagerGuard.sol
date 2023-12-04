// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { FunctionGuard } from "./FunctionGuard.sol";
import { Governable } from "../utils/Governable.sol";

contract GuardManagerGuard is FunctionGuard, Governable {
    event SolvGuardsSetForbidden();

	string public constant SET_GUARD = "setGuard(address)";

	bool public allowSetGuard;
	
	constructor(address safeAccount_, address governor_) Governable(governor_) {
		allowSetGuard = true;
		string[] memory funcs = new string[](1);
		funcs[0] = SET_GUARD;
		_addContractFuncs(safeAccount_, funcs);
	}

	function forbidSetGuard() external virtual onlyGovernor {
		allowSetGuard = false;
        emit SolvGuardsSetForbidden();
	}

	function _checkTransaction(TxData calldata txData_)
		internal
        virtual
		override
        returns (CheckResult memory result)
	{
		if (allowSetGuard) {
			return super._checkTransaction(txData_);
		}
		result.success = false;
		result.message = "GuardManagerGuard: set guard not allowed";
	}
}