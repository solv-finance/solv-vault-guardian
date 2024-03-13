// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "./Type.sol";
import {IBaseAuthorization} from "./IBaseAuthorization.sol";
import {BaseAuthorization} from "./BaseAuthorization.sol";
import {FunctionAuthorization} from "./FunctionAuthorization.sol";

contract SolvVaultGuardianBase is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AllowSetGuard(bool isSetGuardAllowed);
    event SetAuthorization(address indexed to, address indexed authorization);
    event RemoveAuthorization(address indexed to, address indexed authorization);
    event SetNativeTokenTransferAllowed(bool isNativeTokenTransferAllowed);
    event AddNativeTokenReceiver(address indexed receiver);
    event RemoveNativeTokenReceiver(address indexed receiver);

    string public constant SAFE_MULITSEND_FUNC_MULTI_SEND = "multiSend(bytes)";

    EnumerableSet.AddressSet internal _toAddresses;
    //to => authorization
    mapping(address => address) public authorizations;

    address public immutable safeAccount;
    address public immutable safeMultiSend;

    bool public allowSetGuard;
    bool public allowEnableModule;
    bool public allowNativeTokenTransfer;
    mapping(address => bool) public nativeTokenReceiver;

    constructor(address safeAccount_, address safeMultiSend_, address governor_, bool allowSetGuard_)
        FunctionAuthorization(address(this), governor_)
    {
        safeAccount = safeAccount_;
        safeMultiSend = safeMultiSend_;
        _setGuardAllowed(allowSetGuard_);
        _setNativeTokenTransferAllowed(false);
    }

    function setGuardAllowed(bool allowed_) external virtual onlyGovernor {
        _setGuardAllowed(allowed_);
    }

    function _setGuardAllowed(bool allowed_) internal virtual {
        allowSetGuard = allowed_;
        emit AllowSetGuard(allowed_);
    }

    function setEnableModule(bool allowed_) external onlyGovernor {
        allowEnableModule = allowed_;
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

    function setAuthorization(address to_, address authorization_) external virtual onlyGovernor {
        _setAuthorization(to_, authorization_);
    }

    function removeAuthorization(address to_) external virtual onlyGovernor {
        _removeAuthorization(to_);
    }

    function getAllToAddresses() external view virtual returns (address[] memory) {
        return _toAddresses.values();
    }

    function addContractFuncs(address contract_, address acl_, string[] memory funcList_)
        external
        virtual
        onlyGovernor
    {
        _addContractFuncsWithACL(contract_, acl_, funcList_);
    }

    function removeContractFuncs(address contract_, string[] calldata funcList_) external virtual onlyGovernor {
        _removeContractFuncs(contract_, funcList_);
    }

    function addContractFuncsSig(address contract_, address acl_, bytes4[] calldata funcSigList_)
        external
        virtual
        onlyGovernor
    {
        _addContractFuncsSigWithACL(contract_, acl_, funcSigList_);
    }

    function removeContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) external virtual onlyGovernor {
        _removeContractFuncsSig(contract_, funcSigList_);
    }

    function setContractACL(address contract_, address acl_) external virtual onlyGovernor {
        _setContractACL(contract_, acl_);
    }

    function _setAuthorization(address to_, address authorization_) internal virtual {
        require(
            IERC165(authorization_).supportsInterface(type(IBaseAuthorization).interfaceId),
            "SolvVaultGuardian: invalid authorization"
        );
        _toAddresses.add(to_);
        authorizations[to_] = authorization_;
        emit SetAuthorization(to_, authorization_);
    }

    function _removeAuthorization(address to_) internal virtual {
        require(_toAddresses.contains(to_), "SolvVaultGuardian: authorization not exist");
        address old = authorizations[to_];
        delete authorizations[to_];
        _toAddresses.remove(to_);
        emit RemoveAuthorization(to_, old);
    }

    function _checkSafeTransaction(address to, uint256 value, bytes calldata data, address msgSender)
        internal
        virtual
    {
        if (data.length == 0) {
            return _checkNativeTransfer(to, value);
        }

        if (data.length < 4) {
            revert("FunctionAuthorization: invalid txData");
        }

        bytes4 selector = _getSelector(data);

        if (to == safeMultiSend && selector == bytes4(keccak256(bytes(SAFE_MULITSEND_FUNC_MULTI_SEND)))) {
            return _checkMultiSendTransactions(to, value, data, msgSender);
        } else {
            return _checkSingleTransaction(to, value, data, msgSender);
        }
    }

    function _checkMultiSendTransactions(address, /* to */ uint256, /* value */ bytes calldata data, address msgSender)
        internal
        virtual
    {
        uint256 multiSendDataLength = uint256(bytes32(data[4 + 32:4 + 32 + 32]));
        bytes calldata multiSendData = data[4 + 32 + 32:4 + 32 + 32 + multiSendDataLength];
        uint256 startIndex = 0;
        while (startIndex < multiSendData.length) {
            (address innerTo, uint256 innerValue, bytes calldata innerData, uint256 endIndex) =
                _unpackMultiSend(multiSendData, startIndex);
            _checkSafeTransaction(innerTo, innerValue, innerData, msgSender);
            startIndex = endIndex;
        }
    }

    function _checkSingleTransaction(address to, uint256 value, bytes calldata data, address msgSender)
        internal
        virtual
    {
        Type.TxData memory txData = Type.TxData({from: msgSender, to: to, value: value, data: data});

        // check safe account enableModule
        if (to == safeAccount && data.length >= 4 && bytes4(data[0:4]) == bytes4(keccak256("enableModule(address)"))) {
            require(allowEnableModule, "SolvVaultGuardian: enableModule disabled");
            return;
        }

        // check safe account setGuard
        if (to == safeAccount && bytes4(data[0:4]) == bytes4(keccak256("setGuard(address)"))) {
            require(allowSetGuard, "SolvVaultGuardian: setGuard disabled");
            return;
        }

        // authorization check
        if (authorizations[to] != address(0)) {
            Type.CheckResult memory result = BaseAuthorization(authorizations[to]).authorizationCheckTransaction(txData);
            if (!result.success) {
                revert(result.message);
            }
            return;
        }

        // general config check
        if (_contracts.contains(to)) {
            Type.CheckResult memory result = BaseAuthorization(address(this)).authorizationCheckTransaction(txData);
            if (!result.success) {
                revert(result.message);
            }
            return;
        }

        revert("SolvVaultGuardian: unauthorized contract");
    }

    function _checkNativeTransfer(address to, uint256 /* value_ */ ) internal view virtual {
        if (to == safeAccount) {
            return;
        }
        if (allowNativeTokenTransfer) {
            if (nativeTokenReceiver[to]) {
                return;
            } else {
                revert("SolvVaultGuardian: native token receiver not allowed");
            }
        } else {
            revert("SolvVaultGuardian: native token transfer not allowed");
        }
    }

    function _unpackMultiSend(bytes calldata transactions, uint256 startIndex)
        internal
        pure
        virtual
        returns (address to, uint256 value, bytes calldata data, uint256 endIndex)
    {
        uint256 offset = 0;
        uint256 length = 1;
        offset += length;

        // address 20 bytes
        length = 20;
        to = address(bytes20(transactions[startIndex + offset:startIndex + offset + length]));
        offset += length;

        // value 32 bytes
        length = 32;
        value = uint256(bytes32(transactions[startIndex + offset:startIndex + offset + length]));
        offset += length;

        // datalength 32 bytes
        length = 32;
        uint256 dataLength = uint256(bytes32(transactions[startIndex + offset:startIndex + offset + length]));
        offset += length;

        // data
        data = transactions[startIndex + offset:startIndex + offset + dataLength];

        endIndex = startIndex + offset + dataLength;
    }
}
