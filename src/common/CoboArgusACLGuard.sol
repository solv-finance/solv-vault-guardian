// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseGuard} from "../common/BaseGuard.sol";

interface CoboArgusACL {
	enum AuthResult {
    	FAILED,
    	SUCCESS
	}
	struct TransactionData {
    	address from; // `msg.sender` who performs the transaction a.k.a wallet address.
    	address delegate; // Delegate who calls executeTransactions().
    	// Same as CallData
    	uint256 flag; // 0x1 delegate call, 0x0 call.
    	address to;
    	uint256 value;
    	bytes data; // calldata
    	bytes hint;
    	bytes extra;
	}

	struct AuthorizerReturnData {
    	AuthResult result;
    	string message;
    	bytes data; // Authorizer return data. usually used for hint purpose.
	}

	function preExecCheck(
        TransactionData calldata transaction
    ) external returns (AuthorizerReturnData memory authData);
}

contract CoboArgusACLGuard  {
	using EnumerableSet for EnumerableSet.AddressSet;

	event AddStrategyACL(address indexed strategy, address indexed acl);

	EnumerableSet.AddressSet internal _strategies;

	mapping(address => EnumerableSet.AddressSet) internal _coboArgusACLs;

	function getStrategyACLs(address strategy_) external view returns (address[] memory) {
		return _coboArgusACLs[strategy_].values();
	}

	function getStrategies() external view returns (address[] memory) {
		return _strategies.values();
	}

	function _addStrategyACLS(address strategy_, address[] memory strategyACLs_) internal {
		if (_strategies.add(strategy_)) {
			for (uint256 i = 0; i < strategyACLs_.length; i++) {
				if (_coboArgusACLs[strategy_].add(strategyACLs_[i])) {
					emit AddStrategyACL(strategy_, strategyACLs_[i]);
				}
			}
		}
	}

	function _executeACL(
		BaseGuard.TxData calldata txData
	) internal virtual returns (BaseGuard.CheckResult memory result)  {
		address strategy = txData.to;
		for (uint i = 0; i < _coboArgusACLs[strategy].length(); i++) {
			address acl = _coboArgusACLs[strategy].at(i);
			CoboArgusACL.AuthorizerReturnData memory authData = CoboArgusACL(acl).preExecCheck(
				CoboArgusACL.TransactionData({
					from: txData.from,
					delegate: txData.from,
					flag: 0,
					to: txData.to,
					value: txData.value,
					data: txData.data,
					hint: "",
					extra: ""
				}));
			if (authData.result == CoboArgusACL.AuthResult.FAILED) {
				result.success = false;
				result.message = authData.message;
			}
		}
		result.success = true;
		return result;
	}
}