// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {BaseAuthorizer} from "../common/BaseAuthorizer.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {TransactionData} from "../common/Types.sol";

contract TransferAuthorizer is BaseAuthorizer {
	using EnumerableSet for EnumerableSet.AddressSet;

	event TokenAdded(address indexed token);
	event TokenRemoved(address indexed token);
	event TokenReceiverAdded(address indexed token, address indexed receiver);
    event TokenReceiverRemoved(address indexed token, address indexed receiver);

	// function transfer(address,uint256)
    bytes4 constant TRANSFER_SELECTOR = 0xa9059cbb;
	address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	EnumerableSet.AddressSet private _tokens;
	//token => receivers
	mapping(address => EnumerableSet.AddressSet) private _tokenToReceivers;

    struct TokenReceiver {
        address token;
        address receiver;
    }
	
	constructor(address safeguard_) BaseAuthorizer(safeguard_) {}	

	function addTokenReceivers(TokenReceiver[] memory tokenReceivers) external onlySafeguard {
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

	function removeTokenReceivers(TokenReceiver[] memory tokenReceivers) external onlySafeguard {
		for (uint256 i = 0; i < tokenReceivers.length; i++) {
			address token = tokenReceivers[i].token;
			address receiver = tokenReceivers[i].receiver;
			if (_tokenToReceivers[token].remove(receiver)) {
				emit TokenReceiverRemoved(token, receiver);
			}
			if (_tokenToReceivers[token].length() == 0) {
				if (_tokens.remove(token)) {
					emit TokenRemoved(token);
				}
			}
		}
	}

	function getAllToken() external view returns (address[] memory) {
        return _tokens.values();
    }

	function getTokenReceivers(address token) external view returns (address[] memory) {
        return _tokenToReceivers[token].values();
    }

	function _checkTransaction( TransactionData calldata txData ) internal virtual override view returns (bool) {
		if (
            txData.data.length >= 68 && // 4 + 32 + 32
            bytes4(txData.data[0:4]) == TRANSFER_SELECTOR &&
            txData.value == 0
        ) {
            // ETH transfer not allowed and token in white list.
            (address recipient /*uint256 amount*/, ) = abi.decode(txData.data[4:], (address, uint256));
            address token = txData.to;
            if (_tokenToReceivers[token].contains(recipient)) {
				return true;
            }
        } else if (txData.data.length == 0 && txData.value > 0) {
            // Contract call not allowed and token in white list.
            address recipient = txData.to;
            if (_tokenToReceivers[ETH].contains(recipient)) {
				return true;
            }
        }

		return false;
	}

}