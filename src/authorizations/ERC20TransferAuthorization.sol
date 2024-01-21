// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract ERC20TransferAuthorization is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_ERC20TransferAuthorization";
    int256 public constant VERSION = 1;

    string internal constant ERC20_TRANSFER_FUNC = "transfer(address,uint256)";
    bytes4 internal constant TRANSFER_SELECTOR = 0xa9059cbb;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event TokenReceiverAdded(address indexed token, address indexed receiver);

    address public safeAccount;
    string[] internal _transferFuncs;

    EnumerableSet.AddressSet internal _tokenSet;
    mapping(address => EnumerableSet.AddressSet) internal _allowedTokenReceivers;

    struct TokenReceivers {
        address token;
        address[] receivers;
    }

    constructor(address safeMultiSendContract_, address caller_, TokenReceivers[] memory tokenReceivers_)
        FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor())
    {
        _transferFuncs = new string[](1);
        _transferFuncs[0] = ERC20_TRANSFER_FUNC;
        _addTokenReceivers(tokenReceivers_);
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

    function _checkSingleTx(address, /* from_ */ address to_, bytes calldata data_, uint256 value_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result)
    {
        if (data_.length == 68 && bytes4(data_[0:4]) == TRANSFER_SELECTOR && value_ == 0) {
            (address recipient, /* uint256 amount */ ) = abi.decode(data_[4:], (address, uint256));
            if (!_allowedTokenReceivers[to_].contains(recipient)) {
                result.success = false;
                result.message = "ERC20TransferAuthorization: ERC20 receiver not allowed";
            } else {
                result.success = true;
            }
        } else {
            result.success = false;
            result.message = "ERC20TransferAuthorization: not ERC20 Transfer";
            return result;
        }
    }
}
