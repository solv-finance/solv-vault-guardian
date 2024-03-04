// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC20Authorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_ERC20Authorization";
    int256 public constant VERSION = 1;

    string internal constant ERC20_APPROVE_FUNC = "approve(address,uint256)";
    string internal constant ERC20_INCREASE_ALLOWANCE_FUNC = "increaseAllowance(address,uint256)";
    string internal constant ERC20_DECREASE_ALLOWANCE_FUNC = "decreaseAllowance(address,uint256)";
    bytes4 internal constant APPROVE_SELECTOR = 0x095ea7b3;
    bytes4 internal constant INCREASE_ALLOWANCE_SELECTOR = 0x39509351;
    bytes4 internal constant DECREASE_ALLOWANCE_SELECTOR = 0xa457c2d7;

    string internal constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";
    bytes4 internal constant TRANSFER_SELECTOR = 0xa9059cbb;

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
        address caller_,
        TokenSpenders[] memory tokenSpenders_,
        TokenReceivers[] memory tokenReceivers_
    ) FunctionAuthorization(caller_, Governable(caller_).governor()) {
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

    function addTokenReceivers(TokenReceivers[] calldata tokenReceiversList_) external virtual onlyGovernor {
        _addTokenReceivers(tokenReceiversList_);
    }

    function removeTokenReceivers(TokenReceivers[] calldata tokenReceiversList_) external virtual onlyGovernor {
        _removeTokenReceivers(tokenReceiversList_);
    }

    function removeToken(address token_) external virtual onlyGovernor {
        _removeToken(token_);
    }

    function _addTokenSpenders(TokenSpenders[] memory _tokenSpendersList) internal virtual {
        for (uint256 i = 0; i < _tokenSpendersList.length; i++) {
            _addTokenSpenders(_tokenSpendersList[i].token, _tokenSpendersList[i].spenders);
        }
    }

    function _removeTokenSpenders(TokenSpenders[] memory _tokenSpendersList) internal virtual {
        for (uint256 i = 0; i < _tokenSpendersList.length; i++) {
            _removeTokenSpenders(_tokenSpendersList[i].token, _tokenSpendersList[i].spenders);
        }
    }

    function _addTokenSpenders(address _token, address[] memory _spenders) internal virtual {
        if (_tokenSet.add(_token)) {
            emit TokenAdded(_token);
        }
        _addContractFuncs(_token, _approveFuncs);
        for (uint256 i = 0; i < _spenders.length; i++) {
            if (_allowedTokenSpenders[_token].add(_spenders[i])) {
                emit TokenSpenderAdded(_token, _spenders[i]);
            }
        }
    }

    function _removeTokenSpenders(address _token, address[] memory _spenders) internal virtual {
        for (uint256 i = 0; i < _spenders.length; i++) {
            if (_allowedTokenSpenders[_token].remove(_spenders[i])) {
                emit TokenSpenderAdded(_token, _spenders[i]);
            }
        }
    }

    function _addTokenReceivers(TokenReceivers[] memory _tokenReceiversList) internal virtual {
        for (uint256 i = 0; i < _tokenReceiversList.length; i++) {
            _addTokenReceivers(_tokenReceiversList[i].token, _tokenReceiversList[i].receivers);
        }
    }

    function _removeTokenReceivers(TokenReceivers[] memory _tokenReceiversList) internal virtual {
        for (uint256 i = 0; i < _tokenReceiversList.length; i++) {
            _removeTokenReceivers(_tokenReceiversList[i].token, _tokenReceiversList[i].receivers);
        }
    }

    function _addTokenReceivers(address _token, address[] memory _receivers) internal virtual {
        if (_tokenSet.add(_token)) {
            emit TokenAdded(_token);
        }
        _addContractFuncs(_token, _transferFuncs);
        for (uint256 i = 0; i < _receivers.length; i++) {
            if (_allowedTokenReceivers[_token].add(_receivers[i])) {
                emit TokenReceiverAdded(_token, _receivers[i]);
            }
        }
    }

    function _removeTokenReceivers(address _token, address[] memory _receivers) internal virtual {
        for (uint256 i = 0; i < _receivers.length; i++) {
            if (_allowedTokenReceivers[_token].remove(_receivers[i])) {
                emit TokenReceiverAdded(_token, _receivers[i]);
            }
        }
    }

    function _removeToken(address _token) internal virtual {
        _removeTokenSpenders(_token, _allowedTokenSpenders[_token].values());
        _removeTokenReceivers(_token, _allowedTokenReceivers[_token].values());
        if (_tokenSet.remove(_token)) {
            _removeContractFuncs(_token, _approveFuncs);
            _removeContractFuncs(_token, _transferFuncs);
            emit TokenRemoved(_token);
        }
    }

    function getAllTokens() external view returns (address[] memory) {
        return _tokenSet.values();
    }

    function getTokenSpenders(address token) external view returns (address[] memory) {
        return _allowedTokenSpenders[token].values();
    }

    function getTokenReceivers(address token) external view returns (address[] memory) {
        return _allowedTokenReceivers[token].values();
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        result = super._authorizationCheckTransaction(txData_);
        if (result.success) {
            bytes4 selector = _getSelector(txData_.data);
            if (selector == TRANSFER_SELECTOR) {
                (address receiver, /* uint256 value */ ) = abi.decode(txData_.data[4:], (address, uint256));
                if (!_allowedTokenReceivers[txData_.to].contains(receiver)) {
                    result.success = false;
                    result.message = "ERC20Authorization: ERC20 receiver not allowed";
                }
            } else if (selector == APPROVE_SELECTOR || selector == INCREASE_ALLOWANCE_SELECTOR || selector == DECREASE_ALLOWANCE_SELECTOR) {
                (address spender, /* uint256 allowance */ ) = abi.decode(txData_.data[4:], (address, uint256));
                if (!_allowedTokenSpenders[txData_.to].contains(spender)) {
                    result.success = false;
                    result.message = "ERC20Authorization: ERC20 spender not allowed";
                }
            } else {
                result.success = false;
                result.message = "ERC20Authorization: not allowed selector";
            }
        }
    }
}

