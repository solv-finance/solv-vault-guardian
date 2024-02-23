// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC20Authorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_ERC20ApproveAuthorization";
    int256 public constant VERSION = 1;

    string internal constant ERC20_APPROVE_FUNC = "approve(address,uint256)";
    string internal constant ERC20_INCREASE_ALLOWANCE_FUNC = "increaseAllowance(address,uint256)";
    string internal constant ERC20_DECREASE_ALLOWANCE_FUNC = "decreaseAllowance(address,uint256)";

    string internal constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";
    bytes4 internal constant TRANSFER_SELECTOR = 0xa9059cbb;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event TokenSpenderAdded(address indexed token, address indexed spender);
    event TokenReceiverAdded(address indexed token, address indexed receiver);

    struct TokenReceivers {
        address token;
        address[] receivers;
    }

    struct TokenSpenders {
        address token;
        address[] spenders;
    }

    address public safeAccount;
    string[] internal _approveFuncs;
    string[] internal _transferFuncs;

    EnumerableSet.AddressSet internal _tokenSet;
    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenSpenders;
    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenReceivers;

    constructor(
        address safeMultiSendContract_,
        address caller_,
        TokenSpenders[] memory tokenSpenders_,
        TokenReceivers[] memory tokenReceivers_
    ) FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor()) {
        _approveFuncs = new string[](3);
        _approveFuncs[0] = ERC20_APPROVE_FUNC;
        _approveFuncs[1] = ERC20_INCREASE_ALLOWANCE_FUNC;
        _approveFuncs[2] = ERC20_DECREASE_ALLOWANCE_FUNC;
        _addTokenSpenders(tokenSpenders_);

        _transferFuncs = new string[](1);
        _transferFuncs[0] = ERC20_TRANSFER_FUNC;
        _addTokenReceivers(tokenReceivers_);
    }

    function addTokenSpenders(TokenSpenders[] calldata tokenSpendersList_) external virtual onlyGovernor {
        _addTokenSpenders(tokenSpendersList_);
    }

    function removeTokenSpenders(TokenSpenders[] calldata tokenSpendersList_) external virtual onlyGovernor {
        _removeTokenSpenders(tokenSpendersList_);
    }

    function _addTokenSpenders(TokenSpenders[] memory _tokenSpendersList) internal virtual {
        for (uint256 i = 0; i < _tokenSpendersList.length; i++) {
            _addTokenSpenders(_tokenSpendersList[i]);
        }
    }

    function _removeTokenSpenders(TokenSpenders[] memory _tokenSpendersList) internal virtual {
        for (uint256 i = 0; i < _tokenSpendersList.length; i++) {
            _removeTokenSpenders(_tokenSpendersList[i]);
        }
    }

    function _addTokenSpenders(TokenSpenders memory _tokenSpenders) internal virtual {
        address token = _tokenSpenders.token;
        address[] memory spenders = _tokenSpenders.spenders;
        if (_tokenSet.add(token)) {
            _addContractFuncs(token, _approveFuncs);
            emit TokenAdded(token);
        }
        for (uint256 i = 0; i < spenders.length; i++) {
            if (_allowedTokenSpenders[token].add(spenders[i])) {
                emit TokenSpenderAdded(token, spenders[i]);
            }
        }
    }

    function _removeTokenSpenders(TokenSpenders memory _tokenSpenders) internal virtual {
        address token = _tokenSpenders.token;
        address[] memory spenders = _tokenSpenders.spenders;
        for (uint256 i = 0; i < spenders.length; i++) {
            if (_allowedTokenSpenders[token].remove(spenders[i])) {
                emit TokenSpenderAdded(token, spenders[i]);
            }
        }
        if (_allowedTokenSpenders[token].length() == 0) {
            if (_tokenSet.remove(token)) {
                _removeContractFuncs(token, _approveFuncs);
                emit TokenRemoved(token);
            }
        }
    }

    function addTokenReceivers(TokenReceivers[] calldata tokenReceiversList_) external virtual onlyGovernor {
        _addTokenReceivers(tokenReceiversList_);
    }

    function removeTokenReceivers(TokenReceivers[] calldata tokenReceiversList_) external virtual onlyGovernor {
        _removeTokenReceivers(tokenReceiversList_);
    }

    function _addTokenReceivers(TokenReceivers[] memory _tokenReceiversList) internal virtual {
        for (uint256 i = 0; i < _tokenReceiversList.length; i++) {
            _addTokenReceivers(_tokenReceiversList[i]);
        }
    }

    function _removeTokenReceivers(TokenReceivers[] memory _tokenReceiversList) internal virtual {
        for (uint256 i = 0; i < _tokenReceiversList.length; i++) {
            _removeTokenReceivers(_tokenReceiversList[i]);
        }
    }

    function _addTokenReceivers(TokenReceivers memory _tokenReceivers) internal virtual {
        address token = _tokenReceivers.token;
        address[] memory receivers = _tokenReceivers.receivers;
        if (_tokenSet.add(token)) {
            _addContractFuncs(token, _transferFuncs);
            emit TokenAdded(token);
        }
        for (uint256 i = 0; i < receivers.length; i++) {
            if (_allowedTokenReceivers[token].add(receivers[i])) {
                emit TokenReceiverAdded(token, receivers[i]);
            }
        }
    }

    function _removeTokenReceivers(TokenReceivers memory _tokenReceivers) internal virtual {
        address token = _tokenReceivers.token;
        address[] memory receivers = _tokenReceivers.receivers;
        for (uint256 i = 0; i < receivers.length; i++) {
            if (_allowedTokenReceivers[token].remove(receivers[i])) {
                emit TokenReceiverAdded(token, receivers[i]);
            }
        }
        if (_allowedTokenReceivers[token].length() == 0) {
            if (_tokenSet.remove(token)) {
                _removeContractFuncs(token, _transferFuncs);
                emit TokenRemoved(token);
            }
        }
    }

    function getAllTokens() external view returns (address[] memory) {
        return _tokenSet.values();
    }

    function getTokenReceivers(address token) external view returns (address[] memory) {
        return _allowedTokenReceivers[token].values();
    }

    function getTokenSpenders(address token) external view returns (address[] memory) {
        return _allowedTokenSpenders[token].values();
    }

    function _checkSingleTx(address from_, address to_, bytes calldata data_, uint256 value_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        result = super._checkSingleTx(from_, to_, data_, value_);
        if (result.success) {
            if (_getSelector(data_) == TRANSFER_SELECTOR) {
                (address to, /* uint256 value */ ) = abi.decode(data_[4:], (address, uint256));
                if (!_allowedTokenReceivers[to_].contains(to)) {
                    result.success = false;
                    result.message = "ERC20TransferAuthorization: ERC20 receiver not allowed";
                }
            } else {
                (address spender, /* uint256 allowance */ ) = abi.decode(data_[4:], (address, uint256));
                if (!_allowedTokenSpenders[to_].contains(spender)) {
                    result.success = false;
                    result.message = "ERC20ApproveAuthorization: ERC20 spender not allowed";
                }
            }
        }
    }
}
