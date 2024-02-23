// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "./Type.sol";
import {IBaseAuthorization} from "./IBaseAuthorization.sol";
import {BaseAuthorization} from "./BaseAuthorization.sol";
import {FunctionAuthorization} from "./FunctionAuthorization.sol";

contract SolvVaultGuardianBase is FunctionAuthorization {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AllowSetGuard(bool isSetGuardAllowed);
    event AddAuthorization(address indexed to, address indexed authorization);
    event RemoveAuthorization(address indexed to, address indexed authorization);
    event UpdateAuthorization(address indexed to, address indexed oldAuthorization, address newAuthorization);
    event SetNativeTokenTransferAllowed(bool isNativeTokenTransferAllowed);
    event AddNativeTokenReceiver(address indexed receiver);
    event RemoveNativeTokenReceiver(address indexed receiver);

    EnumerableSet.AddressSet internal _toAddresses;
    //to => authorization
    mapping(address => address) public authorizations;

    address public immutable safeAccount;
    bool public allowSetGuard;
    bool public allowNativeTokenTransfer;
    mapping(address => bool) public nativeTokenReceiver;

    constructor(address safeAccount_, address safeMultiSend_, address governor_, bool allowSetGuard_)
        FunctionAuthorization(safeMultiSend_, address(this), governor_)
    {
        safeAccount = safeAccount_;
        _setGuardAllowed(allowSetGuard_);
        _setNativeTokenTransferAllowed(false);
    }

    function setGuardAllowed(bool allowed_) external virtual onlyGovernor {
        _setGuardAllowed(allowed_);
    }

    function _setGuardAllowed(bool allowed_) internal virtual {
        allowSetGuard = allowed_;
        emit AllowSetGuard(allowed_);
    }

    function setNativeTokenTransferAllowed(bool allowed_) external virtual onlyGovernor {
        _setNativeTokenTransferAllowed(allowed_);
    }

    function _setNativeTokenTransferAllowed(bool allowed_) internal virtual {
        allowNativeTokenTransfer = allowed_;
        emit SetNativeTokenTransferAllowed(allowed_);
    }

    function addNativeTokenReceiver(address[] calldata receivers_) external virtual onlyGovernor {
        for (uint256 i = 0; i < receivers_.length; i++) {
            nativeTokenReceiver[receivers_[i]] = true;
            emit AddNativeTokenReceiver(receivers_[i]);
        }
    }

    function removeNativeTokenReceiver(address[] calldata receivers_) external virtual onlyGovernor {
        for (uint256 i = 0; i < receivers_.length; i++) {
            nativeTokenReceiver[receivers_[i]] = false;
            emit RemoveNativeTokenReceiver(receivers_[i]);
        }
    }

    function addAuthorizations(address to_, address authorization_) external virtual onlyGovernor {
        _addAuthorization(to_, authorization_);
    }

    function removeAuthorizations(address to_) external virtual onlyGovernor {
        _removeAuthorization(to_);
    }

    function updateAuthorization(address to_, address newAuthorization_) external virtual onlyGovernor {
        _updateAuthorization(to_, newAuthorization_);
    }

    function getAllToAddresses() external view virtual returns (address[] memory) {
        return _toAddresses.values();
    }

    function addContractFuncs(address contract_, address acl_, string[] memory funcList_)
        external
        virtual
        onlyGovernor
    {
        _addContractFuncsWithACL(contract_, acl_, funcList_);
    }

    function removeContractFuncs(address contract_, string[] calldata funcList_) external virtual onlyGovernor {
        _removeContractFuncs(contract_, funcList_);
    }

    function addContractFuncsSig(address contract_, address acl_, bytes4[] calldata funcSigList_)
        external
        virtual
        onlyGovernor
    {
        _addContractFuncsSigWithACL(contract_, acl_, funcSigList_);
    }

    function setContractACL(address contract_, address acl_) external virtual onlyGovernor {
        _setContractACL(contract_, acl_);
    }

    function _addAuthorization(address to_, address authorization_) internal virtual {
        require(!_toAddresses.contains(to_), "SolvVaultGuardian: authorization already exist");
        require(authorizations[to_] == address(0), "SolvVaultGuardian: guard already exist");
        require(
            IERC165(authorization_).supportsInterface(type(IBaseAuthorization).interfaceId),
            "SolvVaultGuardian: authorization_ is not IBaseAuthorization"
        );
        _toAddresses.add(to_);
        authorizations[to_] = authorization_;
        emit AddAuthorization(to_, authorization_);
    }

    function _removeAuthorization(address to_) internal virtual {
        require(_toAddresses.contains(to_), "SolvVaultGuardian: authorization not exist");
        address old = authorizations[to_];
        authorizations[to_] = address(0);
        _toAddresses.remove(to_);
        emit RemoveAuthorization(to_, old);
    }

    function _updateAuthorization(address to_, address newAuthorization_) internal virtual {
        require(_toAddresses.contains(to_), "SolvVaultGuardian: authorization not exist");
        address old = authorizations[to_];
        authorizations[to_] = newAuthorization_;
        emit UpdateAuthorization(to_, old, newAuthorization_);
    }

    function _checkSafeTransaction(address to, uint256 value, bytes calldata data, address msgSender)
        internal
        virtual
    {
        if (to == safeAccount && data.length == 0) {
            return;
        }
        Type.TxData memory txData = Type.TxData({from: msgSender, to: to, value: value, data: data});

        //check safe account setGuard
        if (to == safeAccount && data.length >= 4 && bytes4(data[0:4]) == bytes4(keccak256("setGuard(address)"))) {
            require(allowSetGuard, "SolvVaultGuardian: setGuard disabled");
            return;
        }

        //authorization check
        if (authorizations[to] != address(0)) {
            Type.CheckResult memory result = BaseAuthorization(authorizations[to]).authorizationCheckTransaction(txData);
            if (!result.success) {
                revert(result.message);
            }
            return;
        }

        //general config check
        if (_contracts.contains(to)) {
            Type.CheckResult memory result = BaseAuthorization(address(this)).authorizationCheckTransaction(txData);
            if (!result.success) {
                revert(result.message);
            }
            return;
        }

        revert("SolvVaultGuardian: checkTransaction failed");
    }

    function _checkNativeTransfer(address to_, uint256 /* value_ */ )
        internal
        view
        virtual
        override
        returns (Type.CheckResult memory result_)
    {
        if (allowNativeTokenTransfer) {
            if (nativeTokenReceiver[to_]) {
                result_.success = true;
                result_.message = "SolvVaultGuardian: native token transfer allowed";
            } else {
                result_.success = false;
                result_.message = "SolvVaultGuardian: native token receiver not allowed";
            }
        } else {
            result_.success = false;
            result_.message = "SolvVaultGuardian: native token transfer not allowed";
        }
    }
}
