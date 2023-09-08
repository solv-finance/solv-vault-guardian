// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {StrategyGuard} from "../guards/StrategyGuard.sol";

contract GMXV1Guard is StrategyGuard {
	using EnumerableSet for EnumerableSet.AddressSet;

	address public constant GLP_REWAED_ROUTER = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
	mapping(address => EnumerableSet.AddressSet) internal _allowedApprovedTokens;
	constructor(address[] memory acls_) {
		_addStrategyACLS(GLP_REWAED_ROUTER, acls_);
	}
	function _checkTransaction(
		TxData calldata txData_
	) internal virtual override returns (CheckResult memory result_)  {
		result_ = super._checkTransaction(txData_);
		if (!result_.success) {
			return result_;
		}
	}
}