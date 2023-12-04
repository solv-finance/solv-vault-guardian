// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { BaseGuard } from "../../common/BaseGuard.sol";

contract TransferGuard is BaseGuard {
	using EnumerableSet for EnumerableSet.AddressSet;
	string public constant NAME = "TransferGuard";
	uint256 public constant VERSION = 1;

	event TokenAdded(address indexed token);
	event TokenRemoved(address indexed token);
	event TokenReceiverAdded(address indexed token, address indexed receiver);
    event TokenReceiverRemoved(address indexed token, address indexed receiver);

	// function transfer(address,uint256)
    bytes4 constant TRANSFER_SELECTOR = 0xa9059cbb;
	address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	EnumerableSet.AddressSet internal _tokens;
	//token => receivers
	mapping(address => EnumerableSet.AddressSet) internal _tokenToReceivers;

    struct TokenReceiver {
        address token;
        address receiver;
    }

	constructor(TokenReceiver[] memory receivers_) {
		_addTokenReceivers(receivers_);
	}
	
	function _addTokenReceivers(TokenReceiver[] memory tokenReceivers) internal {
		for (uint256 i = 0; i < tokenReceivers.length; i++) {
			address token = tokenReceivers[i].token;
			address receiver = tokenReceivers[i].receiver;
			if (_tokens.add(token)) {
				emit TokenAdded(token);
			}
			if (_tokenToReceivers[token].add(receiver)) {
				emit TokenReceiverAdded(token, receiver);
			}
		}
	}

	function getAllToken() external view returns (address[] memory) {
        return _tokens.values();
    }

	function getTokenReceivers(address token) external view returns (address[] memory) {
        return _tokenToReceivers[token].values();
    }

	function _checkTransaction( TxData calldata txData ) internal virtual override returns (CheckResult memory result) {
		if (
            txData.data.length >= 68 && // 4 + 32 + 32
            bytes4(txData.data[0:4]) == TRANSFER_SELECTOR &&
            txData.value == 0
        ) {
            // ETH transfer not allowed and token in white list.
            (address recipient /*uint256 amount*/, ) = abi.decode(txData.data[4:], (address, uint256));
            address token = txData.to;
            if (_tokenToReceivers[token].contains(recipient)) {
				result.success = true;
				return result;
            } else {
				result.success = false;
				result.message = "TransferGuard: transfer not allowed";
				return result;
			}
        } else if (txData.data.length == 0 && txData.value > 0) {
            // Contract call not allowed and token in white list.
            address recipient = txData.to;
            if (_tokenToReceivers[ETH].contains(recipient)) {
				result.success = true;
				return result;
            } else {
				result.success = false;
				result.message = "TransferGuard: transfer not allowed";
				return result;
			}
        } else {
			//other function ignore
			result.success = true;
			result.message = "TransferGuard: other function ignore";
			return result;
		}
	}

}