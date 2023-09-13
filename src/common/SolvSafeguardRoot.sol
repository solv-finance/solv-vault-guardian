// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/console.sol";
import "openzeppelin-contracts-upgradeable/access/Ownableupgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Guard} from "safe-contracts/base/GuardManager.sol";
import {GnosisSafeL2, Enum} from "safe-contracts/GnosisSafeL2.sol";
import {BaseGuard} from "./BaseGuard.sol";


abstract contract SolvSafeguardRoot is Guard, OwnableUpgradeable, UUPSUpgradeable {

    address public safeAccount;
    
    address[] public guards;

	fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    function __SolvSafeguardRootGuard_init(address safeAccount_) internal {
        safeAccount = safeAccount_;
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function _setGuards(address[] memory guards_) internal {
        for (uint256 i = 0; i < guards_.length; i++) {
            require(guards_[i] != address(0), "SolvSafeguard: guard is zero address");
        }
        guards = guards_;
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
            BaseGuard.CheckResult memory result = BaseGuard(guards[i]).checkTransaction(txData);
            if (!result.success) {
                revert(result.message);
            }
        }
	}

    function checkAfterExecution(
        bytes32 txHash,
        bool success
    ) external override {}

    function _authorizeUpgrade(address newImplementation) internal virtual override {}    
}