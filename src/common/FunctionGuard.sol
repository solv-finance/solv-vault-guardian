// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/console.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseGuard} from "../common/BaseGuard.sol";

contract FunctionGuard is BaseGuard {
	using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

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
                console.logString("add func: ");
                console.logAddress(contract_);
                console.logString(funcList_[index]);
                console.logBytes4(funcSelector);
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

    function _checkTransactionWithRecursion(address to_, bytes calldata data_) internal view virtual returns (CheckResult memory result) {
		if (data_.length < 4) {
            result.success = false;
            result.message = "FunctionGuard: invalid txData";
            return result;
		}
		bytes4 selector = _getSelector(data_);
		if (_isAllowedSelector(to_, selector)) {
            result.success = true;
			return result;
		}
        result.success = false;
        result.message = "FunctionGuard: not allowed function";
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