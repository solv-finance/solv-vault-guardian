// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseGuard } from "./BaseGuard.sol";
import "forge-std/console.sol";

abstract contract BaseACL {
	address public caller;
	address public safeAccount;

	constructor(address caller_) {
		caller = caller_;
	}

	modifier onlyCaller() virtual {
        require(msg.sender == caller, "onlyCaller");
        _;
    }

	modifier onlyContract(address _contract) {
        _checkContract(_contract);
        _;
	}

	function preCheck(BaseGuard.TxData calldata txData_) external virtual onlyCaller returns (BaseGuard.CheckResult memory result_) {
		result_ = _preCheck(txData_);
	}

    function _preCheck( BaseGuard.TxData calldata txData_
    ) internal virtual returns (BaseGuard.CheckResult memory result_) {
		(bool success, bytes memory revertData) = address(this).staticcall(_packTxn(txData_));
		result_ = _parseReturnData(success, revertData);
	}

	function _packTxn(BaseGuard.TxData memory txData_) internal pure virtual returns (bytes memory) {
        bytes memory txnData = abi.encode(txData_);
        bytes memory callDataSize = abi.encode(txData_.data.length);
        return abi.encodePacked(txData_.data, txnData, callDataSize);
    }

    function _unpackTxn() internal pure virtual returns (BaseGuard.TxData memory txData_) {
        uint256 end = msg.data.length;
        uint256 callDataSize = abi.decode(msg.data[end - 32:end], (uint256));
        txData_ = abi.decode(msg.data[callDataSize:], (BaseGuard.TxData));
    }

    function _checkContract(address _contract) internal pure {
        require(_contract == _txn().to, "Invalid contract");
    }

	function _txn() internal pure virtual returns (BaseGuard.TxData memory) {
        return _unpackTxn();
    }

    function _parseReturnData(
        bool success,
        bytes memory revertData
    ) internal pure returns (BaseGuard.CheckResult memory result_) {
        if (success) {
            // ACL checking functions should not return any bytes which differs from normal view functions.
            require(revertData.length == 0, "ACL Function return non empty");
			result_.success = true;
        } else {
            if (revertData.length < 68) {
                // 8(bool) + 32(length)
                result_.message = string(revertData);
            } else {
                assembly {
                    // Slice the sighash.
                    revertData := add(revertData, 0x04)
                }
                result_.message = abi.decode(revertData, (string));
            }
        }
    }
}