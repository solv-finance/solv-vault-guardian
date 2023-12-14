// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Governable {
    event NewGovernor(address indexed previousGovernor, address indexed newGovernor);

    address public governor;
    bool public governanceAllowed = true;

    constructor(address governor_) {
        _transferGovernance(governor_);
    }

    modifier onlyGovernor() {
        require(governanceAllowed && governor == msg.sender, "Governable: only governor");
        _;
    }

    function forbidGovernance() external onlyGovernor {
        governanceAllowed = false;
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
