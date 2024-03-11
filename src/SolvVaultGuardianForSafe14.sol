// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {BaseGuard, Enum, Guard} from "safe-contracts-1.4.0/base/GuardManager.sol";
import {BaseAuthorization} from "./common/BaseAuthorization.sol";
import {SolvVaultGuardianBase} from "./common/SolvVaultGuardianBase.sol";

contract SolvVaultGuardianForSafe14 is BaseGuard, SolvVaultGuardianBase {
    event GuardianAllowedTransaction(address indexed to, uint256 value, bytes data, address indexed msgSender);

    constructor(address safeAccount_, address safeMultiSend_, address governor_, bool allowSetGuard_)
        SolvVaultGuardianBase(safeAccount_, safeMultiSend_, governor_, allowSetGuard_)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseAuthorization, BaseGuard)
        returns (bool)
    {
        return interfaceId == type(Guard).interfaceId // 0xe6d7a83a
            || interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

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
