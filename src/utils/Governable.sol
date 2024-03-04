// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Governable {
    
    event NewGovernor(address indexed previousGovernor, address indexed newGovernor);
	event NewPendingGovernor(address indexed previousPendingGovernor, address indexed newPendingGovernor);

    address public governor;
	address public pendingGovernor;

    bool public governanceAllowed = true;

    modifier onlyGovernor() {
        require(governanceAllowed && governor == msg.sender, "Governable: only governor");
        _;
    }

	modifier onlyPendingGovernor() {
		require(pendingGovernor == msg.sender, "Governable: only governor");
		_;
	}

	constructor(address governor_) {
		governor = governor_;
        emit NewGovernor(address(0), governor_);
	}

    function forbidGovernance() external onlyGovernor {
        governanceAllowed = false;
    }

    function transferGovernance(address newPendingGovernor_) external virtual onlyGovernor {
        emit NewPendingGovernor(pendingGovernor, newPendingGovernor_);
		pendingGovernor = newPendingGovernor_;
    }

	function acceptGovernance() external virtual onlyPendingGovernor {
		emit NewGovernor(governor, pendingGovernor);
		governor = pendingGovernor;
		delete pendingGovernor;
	}
}
