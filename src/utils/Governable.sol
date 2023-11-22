// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Context } from "openzeppelin-contracts/contracts/utils/Context.sol";

abstract contract Governable is Context {

	event NewGovernor(address indexed previousGovernor, address indexed newGovernor);

	address public governor;

    constructor(address governor_) {
        _transferGovernance(governor_);
    }

	modifier onlyGovernor() {
		require(governor == _msgSender(), "Governable: only governor");
		_;
	}

	function transferGovernance(address newGovernor_) public onlyGovernor {
		_transferGovernance(newGovernor_);
	}

	function _transferGovernance(address newGovernor_) internal {
		require(newGovernor_ != address(0), "Governable: new governor is the zero address");
        address oldGovernor = governor;
        governor = newGovernor_;
		emit NewGovernor(oldGovernor, newGovernor_);
	}
}