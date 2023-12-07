// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC20TransferAuthorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuard_ERC20TransferAuthorization";
    int256 public constant VERSION = 1;

    string public constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public safeAccount;
    string[] internal _transferFuncs;

    EnumerableSet.AddressSet _tokenSet;
    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenReceivers;

    struct TokenReceiver {
        address token;
        address[] receivers;
    }

    constructor(address caller_) FunctionAuthorization(caller_, Governable(caller_).governor()) {
        _transferFuncs = new string[](1);
        _transferFuncs[0] = ERC20_TRANSFER_FUNC;
    }

    function _guardCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        super._guardCheckTransaction(txData_);
        (address recipient, /*uint256 amount*/ ) = abi.decode(txData_.data[4:], (address, uint256));
        if (txData_.data.length >= 68 && txData_.value == 0) {
            if (_allowedTokenReceivers[txData_.to].contains(recipient)) {
                result.success = true;
            }
        } else if (txData_.data.length == 0 && txData_.value > 0) {
            if (_allowedTokenReceivers[ETH].contains(recipient)) {
                result.success = true;
            }
        } else {
            result.success = false;
            result.message = "ERC20TransferAuthorization: not allowed token receiver";
        }
    }

    function _addTokenReceiver(TokenReceiver[] memory tokenReceivers_) internal {
        for (uint256 i = 0; i < tokenReceivers_.length; i++) {
            _addTokenReceiver(tokenReceivers_[i]);
        }
    }

    function _addTokenReceiver(TokenReceiver memory tokenReceiver_) internal {
        _tokenSet.add(tokenReceiver_.token);
        _addContractFuncs(tokenReceiver_.token, _transferFuncs);
        for (uint256 i = 0; i < tokenReceiver_.receivers.length; i++) {
            _allowedTokenReceivers[tokenReceiver_.token].add(tokenReceiver_.receivers[i]);
        }
    }

    function _removeToken(address token_) internal {
        _removeContractFuncs(token_, _transferFuncs);
        _tokenSet.remove(token_);
    }

    function _removeTokenReceiver(TokenReceiver[] memory tokenReceivers_) internal {}
}
