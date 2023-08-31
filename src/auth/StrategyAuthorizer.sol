// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseAuthorizer} from "../common/BaseAuthorizer.sol";
import {TxData} from "../common/Types.sol";

contract StrategyAuthorizer is BaseAuthorizer {
	using EnumerableSet for EnumerableSet.AddressSet;

	event AddStrategyACL(address indexed strategyACL);

	EnumerableSet.AddressSet internal _strategyACLs;

	function _checkTransaction(
		TxData calldata txData
	) internal view virtual override returns (bool) {
		return false;
	}
}