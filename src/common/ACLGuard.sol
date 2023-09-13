// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/console.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {BaseGuard} from "../common/BaseGuard.sol";
import {BaseACL} from "../common/BaseACL.sol";

contract ACLGuard  {
	using EnumerableSet for EnumerableSet.AddressSet;

	event AddStrategyACL(address indexed strategy, address indexed acl);

	EnumerableSet.AddressSet internal _strategies;

	mapping(address => EnumerableSet.AddressSet) internal _acls;

	function getStrategyACLs(address strategy_) external view returns (address[] memory) {
		return _acls[strategy_].values();
	}

	function getStrategies() external view returns (address[] memory) {
		return _strategies.values();
	}

	function _addStrategyACLS(address strategy_, address[] memory strategyACLs_) internal {
		if (_strategies.add(strategy_)) {
			for (uint256 i = 0; i < strategyACLs_.length; i++) {
				if (_acls[strategy_].add(strategyACLs_[i])) {
					emit AddStrategyACL(strategy_, strategyACLs_[i]);
				}
			}
		}
	}

	function _executeACL(
		BaseGuard.TxData calldata txData
	) internal virtual returns (BaseGuard.CheckResult memory result)  {
		address strategy = txData.to;
		for (uint i = 0; i < _acls[strategy].length(); i++) {
			address acl = _acls[strategy].at(i);
			result = BaseACL(acl).preCheck(txData);
			if (!result.success) {
				return result;
			}
		}
		result.success = true;
		return result;
	}
}