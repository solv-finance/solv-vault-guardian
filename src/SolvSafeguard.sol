// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
import {Guard} from "safe-contracts/base/GuardManager.sol";
import {GnosisSafeL2, Enum} from "safe-contracts/GnosisSafeL2.sol";

contract SolvSafeguard is Guard {
    bytes32 public constant NAME = "SolvSafeguard";
    uint256 public constant VERSION = 1;

    address public immutable cexRechargeAuthorizer;
    address public immutable settlementAuthorizer;
    address public immutable coboArgusAuthorizer;
    address public immutable strategyAuthorizer;
	fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

	constructor(address cexRechargeAuthorizer_, address settlementAuthorizer_, 
                address coboArgusAuthorizer_, address strategyAuthorizer_) {
        cexRechargeAuthorizer = cexRechargeAuthorizer_;
        settlementAuthorizer = settlementAuthorizer_;
        coboArgusAuthorizer = coboArgusAuthorizer_;
        strategyAuthorizer = strategyAuthorizer_;
	}

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external override {
	}

    function checkAfterExecution(
        bytes32 txHash,
        bool success
    ) external override {}

    
}