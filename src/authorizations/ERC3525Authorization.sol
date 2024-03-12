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
    bytes4 internal constant APPROVE_ID_SELECTOR = 0x095ea7b3;
    bytes4 internal constant APPROVE_VALUE_SELECTOR = 0x8cb0a511;

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

    constructor(address caller_, TokenSpenders[] memory tokenSpenders_)
        FunctionAuthorization(caller_, Governable(caller_).governor())
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
            _addContractFuncs(_token, _approveFuncs);
            emit TokenAdded(_token);
        }
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
        if (_allowedTokenSpenders[_token].length() == 0) {
            if (_tokenSet.remove(_token)) {
                _removeContractFuncs(_token, _approveFuncs);
                emit TokenRemoved(_token);
            }
        }
    }

    function getAllTokens() external view returns (address[] memory) {
        return _tokenSet.values();
    }

    function getTokenSpenders(address token) external view returns (address[] memory) {
        return _allowedTokenSpenders[token].values();
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
            if (selector == APPROVE_ID_SELECTOR) {
                (address spender, /* uint256 tokenId */ ) = abi.decode(txData_.data[4:], (address, uint256));
                if (!_allowedTokenSpenders[txData_.to].contains(spender)) {
                    result.success = false;
                    result.message = "ERC3525Authorization: ERC3525 id spender not allowed";
                }
            } else if (selector == APPROVE_VALUE_SELECTOR) {
                ( /* uint256 tokenId */ , address spender, /* uint256 allowance */ ) =
                    abi.decode(txData_.data[4:], (uint256, address, uint256));
                if (!_allowedTokenSpenders[txData_.to].contains(spender)) {
                    result.success = false;
                    result.message = "ERC3525Authorization: ERC3525 value spender not allowed";
                }
            }
        }
    }
}
