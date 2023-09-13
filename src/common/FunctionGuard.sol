// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/console.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {BaseGuard} from "../common/BaseGuard.sol";

contract FunctionGuard is BaseGuard {
	using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant SAFE_MULTI_SEND_CONTRACT = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;
    string public constant SAFE_MULITSEND_FUNC_MULTI_SEND = "multiSend(bytes)";

	event AddContractFunc(address indexed _contract, string func, address indexed sender);
    event AddContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);
    event RemoveContractFunc(address indexed _contract, string func, address indexed sender);
    event RemoveContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);

	EnumerableSet.AddressSet internal _contracts;
	mapping(address => EnumerableSet.Bytes32Set) internal _allowedContractToFunctions;

    function _addContractFuncs(address contract_, string[] memory funcList_) internal {
        require(funcList_.length > 0, "FuncGuard: empty funcList");

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

   function _addContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) internal {
        require(funcSigList_.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        _contracts.add(contract_);
    }

	function getAllContracts() public view returns (address[] memory) {
        return _contracts.values();
    }

	function getFunctionsByContract(address contract_) public view returns (bytes32[] memory) {
        return _allowedContractToFunctions[contract_].values();
    }

	function _checkTransaction(TxData calldata txData_)
		internal
        virtual
		override
        returns (CheckResult memory result)
	{
        return _checkTransactionWithRecursion(txData_.to, txData_.data);
	}

    function _checkTransactionWithRecursion(address to_, bytes calldata data_) internal view 
        virtual returns (CheckResult memory result_) {
        bytes4 selector = _getSelector(data_);

        if (selector == bytes4(keccak256(bytes(SAFE_MULITSEND_FUNC_MULTI_SEND)))) {
            result_ = _checkMultiSend(data_);
        } else {
           if (data_.length < 4) {
                result_.success = false;
                result_.message = "FunctionGuard: invalid txData";
                return result_;
		    }
		    if (_isAllowedSelector(to_, selector)) {
                result_.success = true;
			    return result_;
		    }
            result_.success = false;
            result_.message = "FunctionGuard: not allowed function"; 
        }
    }

    function _checkMultiSend(bytes calldata transactions_) internal view returns (CheckResult memory result_) {
        uint256 offset = 4 + 32;
        uint256 multiSendDataLength = uint256(bytes32(transactions_[offset:offset+32]));
        bytes calldata multiSendData = transactions_[offset+32:offset+32+multiSendDataLength];
        uint256 startIndex = 0;
        while (startIndex < multiSendData.length) {
            (address to, bytes calldata data, uint256 endIndex) = _unpackMultiSend(multiSendData, startIndex);
            if (to != address(0)) {
                result_ = _checkTransactionWithRecursion(to, data);
                if (!result_.success) {
                    return result_;
                }
            }
           
            startIndex = endIndex;
        }

        result_.success = true;
    }

    function _unpackMultiSend(bytes calldata transactions_, uint256 startIndex_) internal pure 
        returns( address to_, bytes calldata data_, uint256 endIndex_) {
        uint256 offset = 0; 
        uint256 length = 1;
        offset += length; 

        //address 20 bytes
        length = 20;
        to_ = address(bytes20(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //value 32 bytes
        length = 32;
        offset += length;

        //datalength 32 bytes
        length = 32;
        uint256 dataLength = uint256(bytes32(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //data
        data_ = transactions_[startIndex_ + offset:startIndex_ + offset + dataLength];

        endIndex_ = startIndex_ + offset + dataLength;
        return (to_, data_, endIndex_);
    }



	 function _isAllowedSelector(address target_, bytes4 selector_) internal view returns (bool) {
        return _allowedContractToFunctions[target_].contains(selector_);
    }

	function _getSelector(bytes calldata data_) internal pure returns (bytes4 selector_) {
        assembly {
            selector_ := calldataload(data_.offset)
        }
    }
}