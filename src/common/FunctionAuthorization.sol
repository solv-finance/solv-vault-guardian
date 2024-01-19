// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {BaseAuthorization} from "../common/BaseAuthorization.sol";
import {BaseACL} from "../common/BaseACL.sol";
import {Multicall} from "../utils/Multicall.sol";

abstract contract FunctionAuthorization is BaseAuthorization, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant SAFE_MULITSEND_FUNC_MULTI_SEND = "multiSend(bytes)";

    event AddContractFunc(address indexed contract_, string func_, address indexed sender_);
    event AddContractFuncSig(address indexed contract_, bytes4 indexed funcSig_, address indexed sender_);
    event RemoveContractFunc(address indexed contract_, string func_, address indexed sender_);
    event RemoveContractFuncSig(address indexed contract_, bytes4 indexed funcSig_, address indexed sender_);
    event SetContractACL(address indexed contract_, address indexed acl_, address indexed sender_);

    address public immutable safeMultiSendContract;
    EnumerableSet.AddressSet internal _contracts;
    mapping(address => EnumerableSet.Bytes32Set) internal _allowedContractToFunctions;
    //contract => acl
    mapping(address => address) internal _contractACL;

    constructor(address safeMultiSendContract_, address caller_, address governor_)
        BaseAuthorization(caller_, governor_)
    {
        safeMultiSendContract = safeMultiSendContract_;
    }

    function addContractFuncs(address contract_, address acl_, string[] memory funcList_)
        external
        virtual
        onlyGovernor
    {
        _addContractFuncs(contract_, funcList_);
        if (acl_ != address(0)) {
            _setContractACL(contract_, acl_);
        }
    }

    function removeContractFuncs(address contract_, string[] calldata funcList_) external virtual onlyGovernor {
        _removeContractFuncs(contract_, funcList_);
    }

    function addContractFuncsSig(address contract_, address acl_, bytes4[] calldata funcSigList_)
        external
        virtual
        onlyGovernor
    {
        _addContractFuncsSig(contract_, funcSigList_);
        if (acl_ != address(0)) {
            _setContractACL(contract_, acl_);
        }
    }

    function removeContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) external virtual onlyGovernor {
        _removeContractFuncsSig(contract_, funcSigList_);
    }

    function setContractACL(address contract_, address acl_) external virtual onlyGovernor {
        _setContractACL(contract_, acl_);
    }

    function getAllContracts() public view virtual returns (address[] memory) {
        return _contracts.values();
    }

    function getFunctionsByContract(address contract_) public view virtual returns (bytes32[] memory) {
        return _allowedContractToFunctions[contract_].values();
    }

    function getACLByContract(address contract_) external view virtual returns (address) {
        return _contractACL[contract_];
    }

    function _addContractFuncs(address contract_, string[] memory funcList_) internal virtual {
        require(funcList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcList_.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList_[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFunc(contract_, funcList_[index], msg.sender);
                emit AddContractFuncSig(contract_, funcSelector, msg.sender);
            }
        }

        _contracts.add(contract_);
    }

    function _addContractFuncsSig(address contract_, bytes4[] memory funcSigList_) internal virtual {
        require(funcSigList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        _contracts.add(contract_);
    }

    function _removeContractFuncs(address contract_, string[] memory funcList_) internal virtual {
        require(funcList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcList_.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList_[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFunctions[contract_].remove(funcSelector32)) {
                emit RemoveContractFunc(contract_, funcList_[index], msg.sender);
                emit RemoveContractFuncSig(contract_, funcSelector, msg.sender);
            }
        }

        if (_allowedContractToFunctions[contract_].length() == 0) {
            delete _contractACL[contract_];
            _contracts.remove(contract_);
        }
    }

    function _removeContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) internal virtual {
        require(funcSigList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].remove(funcSelector32)) {
                emit RemoveContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        if (_allowedContractToFunctions[contract_].length() == 0) {
            delete _contractACL[contract_];
            _contracts.remove(contract_);
        }
    }

    function _setContractACL(address contract_, address acl_) internal virtual {
        _contractACL[contract_] = acl_;
        emit SetContractACL(contract_, acl_, msg.sender);
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        return _authorizationCheckTransactionWithRecursion(txData_.from, txData_.to, txData_.data, txData_.value);
    }

    function _authorizationCheckTransactionWithRecursion(
        address from_,
        address to_,
        bytes calldata data_,
        uint256 value_
    ) internal virtual returns (Type.CheckResult memory result_) {
        if (data_.length == 0) {
            return _checkNativeTransfer(to_, value_);
        }

        if (data_.length < 4) {
            result_.success = false;
            result_.message = "FunctionAuthorization: invalid txData";
            return result_;
        }

        bytes4 selector = _getSelector(data_);

        if (to_ == safeMultiSendContract && selector == bytes4(keccak256(bytes(SAFE_MULITSEND_FUNC_MULTI_SEND)))) {
            result_ = _checkMultiSend(from_, to_, data_, value_);
        } else {
            result_ = _checkSingleTx(from_, to_, data_, value_);
        }
    }

    function _checkMultiSend(address from_, address, /* to_ */ bytes calldata transactions_, uint256 /* value_ */ )
        internal
        virtual
        returns (Type.CheckResult memory result_)
    {
        uint256 multiSendDataLength = uint256(bytes32(transactions_[4 + 32:4 + 32 + 32]));
        bytes calldata multiSendData = transactions_[4 + 32 + 32:4 + 32 + 32 + multiSendDataLength];
        uint256 startIndex = 0;
        while (startIndex < multiSendData.length) {
            (address to, uint256 value, bytes calldata data, uint256 endIndex) =
                _unpackMultiSend(multiSendData, startIndex);
            if (to != address(0)) {
                result_ = _authorizationCheckTransactionWithRecursion(from_, to, data, value);
                if (!result_.success) {
                    return result_;
                }
            }

            startIndex = endIndex;
        }

        result_.success = true;
    }

    function _unpackMultiSend(bytes calldata transactions_, uint256 startIndex_)
        internal
        pure
        virtual
        returns (address to_, uint256 value_, bytes calldata data_, uint256 endIndex_)
    {
        uint256 offset = 0;
        uint256 length = 1;
        offset += length;

        //address 20 bytes
        length = 20;
        to_ = address(bytes20(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //value 32 bytes
        length = 32;
        value_ = uint256(bytes32(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //datalength 32 bytes
        length = 32;
        uint256 dataLength = uint256(bytes32(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //data
        data_ = transactions_[startIndex_ + offset:startIndex_ + offset + dataLength];

        endIndex_ = startIndex_ + offset + dataLength;
    }

    function _checkSingleTx(address from_, address to_, bytes calldata data_, uint256 value_) 
        internal 
        virtual 
        returns (Type.CheckResult memory result_) 
    {
        bytes4 selector = _getSelector(data_);
        if (_isAllowedSelector(to_, selector)) {
            result_.success = true;
            //if allowed, check acl
            if (_contractACL[to_] != address(0)) {
                result_ = BaseACL(_contractACL[to_]).preCheck(from_, to_, data_, value_);
            }
        } else {
            result_.success = false;
            result_.message = "FunctionAuthorization: not allowed function";
        }
        
    }

    function _isAllowedSelector(address target_, bytes4 selector_) internal view virtual returns (bool) {
        return _allowedContractToFunctions[target_].contains(selector_);
    }

    function _getSelector(bytes calldata data_) internal pure virtual returns (bytes4 selector_) {
        assembly {
            selector_ := calldataload(data_.offset)
        }
    }

    // to allow native token transferring, must override this function
    function _checkNativeTransfer(address, /* to */ uint256 /* value_ */ )
        internal
        view
        virtual
        returns (Type.CheckResult memory result_)
    {
        result_.success = false;
        result_.message = "FunctionAuthorization: native token transfer not allowed";
    }
}
