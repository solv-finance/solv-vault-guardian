// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/console.sol";
import {Guard} from "safe-contracts/base/GuardManager.sol";
import {GnosisSafeL2, Enum} from "safe-contracts/GnosisSafeL2.sol";
import {BaseGuard} from "./common/BaseGuard.sol";

contract SolvSafeguard is Guard {
    bytes32 public constant NAME = "SolvSafeguard";
    uint256 public constant VERSION = 1;

    address public immutable safeWallet;
    address public cexRechargeGuard;
    address public settlementGuard;
    address public coboArgusGuard;
    address public strategyGuard;

    address public immutable owner;

    modifier onlyOwner {
        require(msg.sender == owner, "SolvSafeguard: only owner");
        _;
    }

	fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

	constructor(address safeWallet_, address cexRechargeGuard_, address settlementGuard_, 
                address coboArgusGuard_, address strategyGuard_) {
        owner = msg.sender;
        safeWallet = safeWallet_;
        cexRechargeGuard = cexRechargeGuard_;
        settlementGuard = settlementGuard_;
        coboArgusGuard = coboArgusGuard_;
        strategyGuard = strategyGuard_;
	}

    function setCexRechargeGuard(address cexRechargeGuard_) external onlyOwner {
        cexRechargeGuard = cexRechargeGuard_;
    }

    function setSettlementGuard(address settlementGuard_) external onlyOwner {
        settlementGuard = settlementGuard_;
    }

    function setCoboArgusGuard(address coboArgusGuard_) external onlyOwner {
        coboArgusGuard = coboArgusGuard_;
    }

    function setStrategyGuard(address strategyGuard_) external onlyOwner {
        strategyGuard = strategyGuard_;
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
        if (to == safeWallet && data.length == 0) {
            console.logString("SolvSafeguard: checkTransaction: safeWallet");
            return;
        }
        BaseGuard.TxData memory txData = BaseGuard.TxData({
            from: msgSender,
            to: to,
            value: value,
            data: data
        });
        if (cexRechargeGuard != address(0)) {
            BaseGuard.CheckResult memory result = BaseGuard(cexRechargeGuard).checkTransaction(txData);
            require(result.success, result.message);
        }
	}

    function checkAfterExecution(
        bytes32 txHash,
        bool success
    ) external override {}

    
}