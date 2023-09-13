// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Guard} from "safe-contracts/base/GuardManager.sol";
import {GnosisSafeL2, Enum} from "safe-contracts/GnosisSafeL2.sol";
import {BaseGuard} from "./BaseGuard.sol";


abstract contract SolvSafeguardRoot is Guard, Ownable {
    event SolvGuardsSet(address[]);
    event SolvGuardsSetForbidden();

    address public immutable safeAccount;
    address[] public  guards;
    bool public allowSetSolvGuards;

	fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    constructor(address safeAccount_) Ownable() {
        safeAccount = safeAccount_;
        allowSetSolvGuards = true;
    }

    function _setSolvGuards(address[] memory guards_) internal {
        guards = guards_;
        emit SolvGuardsSet(guards_);
    }

    function setSolvGuards(address[] memory guards_) external onlyOwner {
        if (allowSetSolvGuards) {
		    _setSolvGuards(guards_);
        } else {
            revert("not allowed");
        }
    }
    
    function forbidSetSolvGuards() external onlyOwner {
        allowSetSolvGuards = false;
        emit SolvGuardsSetForbidden();
    }

    function getSolvGuards() external view returns (address[] memory) {
        return guards;
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation /*operation*/,
        uint256 /*safeTxGas*/,
        uint256 /*baseGas*/,
        uint256 /*gasPrice*/,
        address /*gasToken*/,
        address payable /*refundReceiver*/,
        bytes memory /*signatures*/,
        address msgSender
    ) external override {
        if (to == safeAccount && data.length == 0) {
            console.logString("SolvSafeguard: checkTransaction: safeWallet");
            return;
        }
        BaseGuard.TxData memory txData = BaseGuard.TxData({
            from: msgSender,
            to: to,
            value: value,
            data: data
        });

        for (uint256 i = 0; i < guards.length; i++) {
            if (guards[i] != address(0)) {
                BaseGuard.CheckResult memory result = BaseGuard(guards[i]).checkTransaction(txData);
                if (!result.success) {
                    revert(result.message);
                }
            }
        }
	}

    function checkAfterExecution(
        bytes32 txHash,
        bool success
    ) external override {}

    
}