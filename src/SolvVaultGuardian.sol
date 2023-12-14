// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "./common/Type.sol";
import {Guard, Enum} from "safe-contracts/base/GuardManager.sol";
import {BaseAuthorization} from "./common/BaseAuthorization.sol";
import {FunctionAuthorization} from "./common/FunctionAuthorization.sol";
import "forge-std/console.sol";

contract SolvVaultGuardian is Guard, FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Authorization {
        string name;
        address executor;
        bool enabled;
    }

    event AllowSetGuard(bool isSetGuardAllowed_);
    event AddAuthorization(string indexed name, address indexed executor_, bool enabled_);
    event RemoveAuthorization(string indexed name, address indexed executor_, bool enabled_);
    event SetAuthorization(string indexed name, address indexed executor_, bool enabled_);
    event SetNativeTokenTransferAllowed(bool isNativeTokenTransferAllowed_);
    event AddNativeTokenReceiver(address indexed receiver_);
    event RemoveNativeTokenReceiver(address indexed receiver_);

    Authorization[] public authorizations;

    address public immutable safeAccount;
    bool public allowSetGuard;
    bool public allowNativeTokenTransfer;
    mapping(address => bool) public nativeTokenReceiver;

    constructor(address safeAccount_, address safeMultiSend_, address governor_, bool allowSetGuard_)
        FunctionAuthorization(address(this), governor_)
    {
        safeAccount = safeAccount_;
        _setGuardAllowed(allowSetGuard_);
        _setNativeTokenTransferAllowed(false);

        string[] memory safeMultiSendFuncs = new string[](1);
        safeMultiSendFuncs[0] = FunctionAuthorization.SAFE_MULITSEND_FUNC_MULTI_SEND;
        _addContractFuncs(safeMultiSend_, safeMultiSendFuncs);
        Authorization memory self =
            Authorization({name: "SolvVaultGuard_GeneralAuthorization", executor: address(this), enabled: true});
        authorizations.push(self);
    }

    function setGuardAllowed(bool allowed_) external virtual onlyGovernor {
        _setGuardAllowed(allowed_);
    }

    function _setGuardAllowed(bool allowed_) internal virtual {
        allowSetGuard = allowed_;
        emit AllowSetGuard(allowed_);
    }

    function setNativeTokenTransferAllowed(bool allowed_) external virtual onlyGovernor {
        _setNativeTokenTransferAllowed(allowed_);
    }

    function _setNativeTokenTransferAllowed(bool allowed_) internal virtual {
        allowNativeTokenTransfer = allowed_;
        emit SetNativeTokenTransferAllowed(allowed_);
    }

    function addNativeTokenReceiver(address[] calldata receivers_) external virtual onlyGovernor {
        for (uint256 i = 0; i < receivers_.length; i++) {
            nativeTokenReceiver[receivers_[i]] = true;
            emit AddNativeTokenReceiver(receivers_[i]);
        }
    }

    function removeNativeTokenReceiver(address[] calldata receivers_) external virtual onlyGovernor {
        for (uint256 i = 0; i < receivers_.length; i++) {
            nativeTokenReceiver[receivers_[i]] = false;
            emit RemoveNativeTokenReceiver(receivers_[i]);
        }
    }

    function addAuthorizations(Authorization[] calldata authorizations_) external virtual onlyGovernor {
        for (uint256 i = 0; i < authorizations_.length; i++) {
            _addAuthorization(authorizations_[i]);
        }
    }

    function removeAuthorizations(address[] calldata executors_) external virtual onlyGovernor {
        for (uint256 i = 0; i < executors_.length; i++) {
            _removeAuthorization(executors_[i]);
        }
    }

    function setAuthorizationEnabled(address executor_, bool enabled_) external virtual onlyGovernor {
        _setAuthorizationEnabled(executor_, enabled_);
    }

    function _addAuthorization(Authorization memory _authorization) internal virtual {
        for (uint256 i = 0; i < authorizations.length; i++) {
            require(authorizations[i].executor != _authorization.executor, "SolvVaultGuard: guard already exist");
        }
        authorizations.push(_authorization);
        emit AddAuthorization(_authorization.name, _authorization.executor, _authorization.enabled);
    }

    function _removeAuthorization(address _executor) internal virtual {
        for (uint256 i = 0; i < authorizations.length; i++) {
            if (authorizations[i].executor == _executor) {
                emit RemoveAuthorization(authorizations[i].name, authorizations[i].executor, authorizations[i].enabled);
                authorizations[i] = authorizations[authorizations.length - 1];
                authorizations.pop();
                break;
            }
        }
    }

    function _setAuthorizationEnabled(address executor_, bool enabled_) internal virtual {
        for (uint256 i = 0; i < authorizations.length; i++) {
            if (authorizations[i].executor == executor_) {
                authorizations[i].enabled = enabled_;
                emit SetAuthorization(authorizations[i].name, authorizations[i].executor, authorizations[i].enabled);
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
    ) external virtual override {
        if (to == safeAccount && data.length == 0) {
            console.logString("SolvVaultGuard: checkTransaction: safeWallet");
            return;
        }
        Type.TxData memory txData = Type.TxData({from: msgSender, to: to, value: value, data: data});

        //check safe account setGuard
        if (to == safeAccount && data.length >= 4 && bytes4(data[0:4]) == bytes4(keccak256("setGuard(address)"))) {
            console.logString("SolvVaultGuard: checkTransaction: setGuard");
            console.log(allowSetGuard);
            require(allowSetGuard, "SolvVaultGuard: setGuard disabled");
            return;
        }

        //check authorizations check
        for (uint256 i = 0; i < authorizations.length; i++) {
            if (authorizations[i].enabled) {
                Type.CheckResult memory result =
                    BaseAuthorization(authorizations[i].executor).authorizationCheckTransaction(txData);
                //if return true, then passed
                if (result.success) {
                    return;
                }
            }
        }

        revert("SolvVaultGuard: checkTransaction failed");
    }

    function checkAfterExecution(bytes32 txHash, bool success) external virtual override {}

    function _checkNativeTransfer(address to_, uint256 /* value_ */)
        internal
        view
        virtual
        override
        returns (Type.CheckResult memory result_)
    {
        if (allowNativeTokenTransfer) {
            if (nativeTokenReceiver[to_]) {
                result_.success = true;
                result_.message = "SolvVaultGuard: native token transfer allowed";
            } else {
                result_.success = false;
                result_.message = "SolvVaultGuard: native token receiver not allowed";
            }
        } else {
            result_.success = false;
            result_.message = "SolvVaultGuard: native token transfer not allowed";
        }
    }
}
