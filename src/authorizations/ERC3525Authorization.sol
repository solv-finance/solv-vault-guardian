// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC3525Authorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_ERC3525Authorization";
    int256 public constant VERSION = 1;

    string internal constant ERC3525_APPROVE_ID_FUNC = "approve(address,uint256)";
    string internal constant ERC3525_APPROVE_VALUE_FUNC = "approve(uint256,address,uint256)";

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
        _approveFuncs = new string[](2);
        _approveFuncs[0] = ERC3525_APPROVE_ID_FUNC;
        _approveFuncs[1] = ERC3525_APPROVE_VALUE_FUNC;
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

    function _checkSingleTx(address from_, address to_, bytes calldata data_, uint256 value_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        result = super._checkSingleTx(from_, to_, data_, value_);
        if (result.success) {
            if (data_.length == 68) {
                // approve id
                (address spender, /* uint256 tokenId */ ) = abi.decode(data_[4:], (address, uint256));
                if (!_allowedTokenSpenders[to_].contains(spender)) {
                    result.success = false;
                    result.message = "ERC3525ApproveAuthorization: ERC3525 id spender not allowed";
                }
            } else {
                // approve value
                ( /* uint256 tokenId */ , address spender, /* uint256 allowance */ ) =
                    abi.decode(data_[4:], (uint256, address, uint256));
                if (!_allowedTokenSpenders[to_].contains(spender)) {
                    result.success = false;
                    result.message = "ERC3525ApproveAuthorization: ERC3525 value spender not allowed";
                }
            }
        }
    }
}
