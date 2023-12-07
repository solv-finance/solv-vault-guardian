// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "./common/Type.sol";
import {Guard, Enum} from "safe-contracts/base/GuardManager.sol";
import {BaseAuthorization} from "./common/BaseAuthorization.sol";
import {FunctionAuthorization} from "./common/FunctionAuthorization.sol";
import "forge-std/console.sol";

contract SolvVaultGuard is Guard, FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Authorization {
        string name;
        address executor;
        bool enable;
    }

    Authorization[] public authorizations;

    address public immutable safeAccount;
    bool public allowSetGuard = true;

    constructor(address safeAccount_, address safeMultiSend_, address governor_)
        FunctionAuthorization(address(this), governor_)
    {
        safeAccount = safeAccount_;
        string[] memory safeMultiSendFuncs = new string[](1);
        safeMultiSendFuncs[0] = FunctionAuthorization.SAFE_MULITSEND_FUNC_MULTI_SEND;
        _addContractFuncs(safeMultiSend_, safeMultiSendFuncs);
        Authorization memory self =
            Authorization({name: "SolvVaultGuard_GeneralAuthorization", executor: address(this), enable: true});
        authorizations.push(self);
    }

    function setGuardAllowed(bool allowed_) external onlyGovernor {
        allowSetGuard = allowed_;
    }

    function addAuthorizations(Authorization[] calldata authorizations_) external onlyGovernor {
        for (uint256 i = 0; i < authorizations_.length; i++) {
            Authorization memory authorization = authorizations_[i];
            //check excutor is not exist
            for (uint256 j = 0; j < authorizations.length; j++) {
                require(authorizations[j].executor != authorization.executor, "SolvVaultGuard: guard already exist");
            }
            authorizations.push(authorization);
        }
    }

    function removeAuthorizations(address[] calldata executors_) external onlyGovernor {
        for (uint256 i = 0; i < executors_.length; i++) {
            address executor = executors_[i];
            for (uint256 j = 0; j < authorizations.length; j++) {
                if (authorizations[j].executor == executor) {
                    authorizations[j] = authorizations[authorizations.length - 1];
                    authorizations.pop();
                    break;
                }
            }
        }
    }

    function enableAuthorization(address executor_, bool enable_) external onlyGovernor {
        for (uint256 i = 0; i < authorizations.length; i++) {
            if (authorizations[i].executor == executor_) {
                authorizations[i].enable = enable_;
                break;
            }
        }
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
    ) external override {
        if (to == safeAccount && data.length == 0) {
            console.logString("SolvVaultGuard: checkTransaction: safeWallet");
            return;
        }
        Type.TxData memory txData = Type.TxData({from: msgSender, to: to, value: value, data: data});

        //check safe account setGuard
        if (to == safeAccount && data.length >= 4 && bytes4(data[0:4]) == bytes4(keccak256("setGuard(address)"))) {
            console.logString("SolvVaultGuard: checkTransaction: setGuard");
            require(allowSetGuard, "SolvVaultGuard: setGuard disabled");
            return;
        }

        //check authorizations check
        bool passed = false;
        for (uint256 i = 0; i < authorizations.length; i++) {
            Type.CheckResult memory result =
                BaseAuthorization(authorizations[i].executor).authorizationCheckTransaction(txData);
            //if reture true, then passed
            if (result.success) {
                passed = true;
                break;
            }
        }

        require(passed, "SolvVaultGuard: checkTransaction: check failed");
    }

    function checkAfterExecution(bytes32 txHash, bool success) external override {}
}
