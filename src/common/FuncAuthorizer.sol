// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseAuthorizer} from "../common/BaseAuthorizer.sol";
import {TxData} from "../common/Types.sol";

contract FuncAuthorizer is BaseAuthorizer {
	using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

	event AddContractFunc(address indexed _contract, string func, address indexed sender);
    event AddContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);
    event RemoveContractFunc(address indexed _contract, string func, address indexed sender);
    event RemoveContractFuncSig(address indexed _contract, bytes4 indexed funcSig, address indexed sender);

	EnumerableSet.AddressSet internal _contracts;
	mapping(address => EnumerableSet.Bytes32Set) internal _allowedContractToFuncs;

    function _addContractFuncs(address _contract, string[] memory funcList) internal {
        require(funcList.length > 0, "empty funcList");

        for (uint256 index = 0; index < funcList.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFuncs[_contract].add(funcSelector32)) {
                emit AddContractFunc(_contract, funcList[index], msg.sender);
                emit AddContractFuncSig(_contract, funcSelector, msg.sender);
            }
        }

        _contracts.add(_contract);
    }

	function getAllContracts() public view returns (address[] memory) {
        return _contracts.values();
    }

	function getFuncsByContract(address _contract) public view returns (bytes32[] memory) {
        return _allowedContractToFuncs[_contract].values();
    }

	function _checkTransaction(TxData calldata txData)
		internal
		view
		override
		returns (bool)
	{
		return false;
	}

	 function _isAllowedSelector(address target, bytes4 selector) internal view returns (bool) {
        return _allowedContractToFuncs[target].contains(selector);
    }

	function _getSelector(bytes calldata data) internal pure returns (bytes4 selector) {
        assembly {
            selector := calldataload(data.offset)
        }
    }
}