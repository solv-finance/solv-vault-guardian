// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Guard, Enum} from "safe-contracts-1.3.0/base/GuardManager.sol";
import {SolvVaultGuardianBase} from "./common/SolvVaultGuardianBase.sol";

contract SolvVaultGuardianForSafe13 is Guard, SolvVaultGuardianBase {
    event GuardianAllowedTransaction(address indexed to, uint256 value, bytes data, address indexed msgSender);

    constructor(address safeAccount_, address safeMultiSend_, address governor_, bool allowSetGuard_)
        SolvVaultGuardianBase(safeAccount_, safeMultiSend_, governor_, allowSetGuard_)
    {}

    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation, /*operation*/
        uint256, /*safeTxGas*/
        uint256, /*baseGas*/
        uint256, /*gasPrice*/
        address, /*gasToken*/
        address payable, /*refundReceiver*/
        bytes memory, /*signatures*/
        address msgSender
    ) external virtual override {
        _checkSafeTransaction(to, value, data, msgSender);
        emit GuardianAllowedTransaction(to, value, data, msgSender);
    }

    function checkAfterExecution(bytes32 txHash, bool success) external virtual override {}
}
