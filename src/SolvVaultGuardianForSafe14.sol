// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {BaseGuard, Enum} from "safe-contracts-1.4.0/base/GuardManager.sol";
import {BaseAuthorization} from "./common/BaseAuthorization.sol";
import {SolvVaultGuardianBase} from "./common/SolvVaultGuardianBase.sol";

contract SolvVaultGuardianForSafe14 is BaseGuard, SolvVaultGuardianBase {
    bool public allowEnableModule;

    constructor(address safeAccount_, address safeMultiSend_, address governor_, bool allowSetGuard_)
        SolvVaultGuardianBase(safeAccount_, safeMultiSend_, governor_, allowSetGuard_)
    {}

    function enableModule(bool enable) external onlyGovernor {
        allowEnableModule = enable;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseAuthorization, BaseGuard)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
        //check safe account enableModule
        if (to == safeAccount && data.length >= 4 && bytes4(data[0:4]) == bytes4(keccak256("enableModule(address)"))) {
            require(allowEnableModule, "SolvVaultGuardian: enableModule disabled");
            return;
        }
        _checkSafeTransaction(to, value, data, msgSender);
    }

    function checkAfterExecution(bytes32 txHash, bool success) external virtual override {}
}
