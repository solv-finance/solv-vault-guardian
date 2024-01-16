// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC20ApproveAuthorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuard_ERC20ApproveAuthorization";
    int256 public constant VERSION = 1;

    string internal constant ERC20_APPROVE_FUNC = "approve(address,uint256)";
    string internal constant ERC20_INCREASE_ALLOWANCE_FUNC = "increaseAllowance(address,uint256)";
    string internal constant ERC20_DECREASE_ALLOWANCE_FUNC = "decreaseAllowance(address,uint256)";
    
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event TokenSpenderAdded(address indexed token, address indexed spender);

    address public safeAccount;
    string[] internal _approveFuncs;

    EnumerableSet.AddressSet internal _tokenSet;
    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenSpenders;

    struct TokenSpenders {
        address token;
        address[] spenders;
    }

    constructor(address safeMultiSendContract_, address caller_, TokenSpenders[] memory tokenSpenders_)
        FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor())
    {
        _approveFuncs = new string[](3);
        _approveFuncs[0] = ERC20_APPROVE_FUNC;
        _approveFuncs[1] = ERC20_INCREASE_ALLOWANCE_FUNC;
        _approveFuncs[2] = ERC20_DECREASE_ALLOWANCE_FUNC;
        _addTokenSpenders(tokenSpenders_);
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

    function getAllTokens() external view returns (address[] memory) {
        return _tokenSet.values();
    }

    function getTokenSpenders(address token) external view returns (address[] memory) {
        return _allowedTokenSpenders[token].values();
    }

}
