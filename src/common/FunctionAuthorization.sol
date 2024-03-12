// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {Type} from "../common/Type.sol";
import {BaseAuthorization} from "../common/BaseAuthorization.sol";
import {IBaseACL} from "../common/IBaseACL.sol";
import {BaseACL} from "../common/BaseACL.sol";
import {Multicall} from "../utils/Multicall.sol";

abstract contract FunctionAuthorization is BaseAuthorization, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddContractFunc(address indexed contract_, string func_, address indexed sender_);
    event AddContractFuncSig(address indexed contract_, bytes4 indexed funcSig_, address indexed sender_);
    event RemoveContractFunc(address indexed contract_, string func_, address indexed sender_);
    event RemoveContractFuncSig(address indexed contract_, bytes4 indexed funcSig_, address indexed sender_);
    event SetContractACL(address indexed contract_, address indexed acl_, address indexed sender_);

    EnumerableSet.AddressSet internal _contracts;
    mapping(address => EnumerableSet.Bytes32Set) internal _allowedContractToFunctions;
    mapping(address => address) internal _contractACL;

    constructor(address caller_, address governor_) BaseAuthorization(caller_, governor_) {}

    function _addContractFuncsWithACL(address contract_, address acl_, string[] memory funcList_) 
        internal 
        virtual 
    {
        _addContractFuncs(contract_, funcList_);
        if (acl_ != address(0)) {
            _setContractACL(contract_, acl_);
        }
    }

    function _addContractFuncsSigWithACL(address contract_, address acl_, bytes4[] calldata funcSigList_)
        internal
        virtual
    {
        _addContractFuncsSig(contract_, funcSigList_);
        if (acl_ != address(0)) {
            _setContractACL(contract_, acl_);
        }
    }

    function getAllContracts() public view virtual returns (address[] memory) {
        return _contracts.values();
    }

    function getFunctionsByContract(address contract_) public view virtual returns (bytes32[] memory) {
        return _allowedContractToFunctions[contract_].values();
    }

    function getACLByContract(address contract_) external view virtual returns (address) {
        return _contractACL[contract_];
    }

    function _addContractFuncs(address contract_, string[] memory funcList_) internal virtual {
        require(funcList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcList_.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList_[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFunc(contract_, funcList_[index], msg.sender);
                emit AddContractFuncSig(contract_, funcSelector, msg.sender);
            }
        }

        _contracts.add(contract_);
    }

    function _addContractFuncsSig(address contract_, bytes4[] memory funcSigList_) internal virtual {
        require(funcSigList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].add(funcSelector32)) {
                emit AddContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        _contracts.add(contract_);
    }

    function _removeContractFuncs(address contract_, string[] memory funcList_) internal virtual {
        require(funcList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcList_.length; index++) {
            bytes4 funcSelector = bytes4(keccak256(bytes(funcList_[index])));
            bytes32 funcSelector32 = bytes32(funcSelector);
            if (_allowedContractToFunctions[contract_].remove(funcSelector32)) {
                emit RemoveContractFunc(contract_, funcList_[index], msg.sender);
                emit RemoveContractFuncSig(contract_, funcSelector, msg.sender);
            }
        }

        if (_allowedContractToFunctions[contract_].length() == 0) {
            delete _contractACL[contract_];
            _contracts.remove(contract_);
        }
    }

    function _removeContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) internal virtual {
        require(funcSigList_.length > 0, "FunctionAuthorization: empty funcList");

        for (uint256 index = 0; index < funcSigList_.length; index++) {
            bytes32 funcSelector32 = bytes32(funcSigList_[index]);
            if (_allowedContractToFunctions[contract_].remove(funcSelector32)) {
                emit RemoveContractFuncSig(contract_, funcSigList_[index], msg.sender);
            }
        }

        if (_allowedContractToFunctions[contract_].length() == 0) {
            delete _contractACL[contract_];
            _contracts.remove(contract_);
        }
    }

    function _setContractACL(address contract_, address acl_) internal virtual {
        require(_contracts.contains(contract_), "FunctionAuthorization: contract not exist");
        if (acl_ != address(0)) {
            require(
                IERC165(acl_).supportsInterface(type(IBaseACL).interfaceId),
                "FunctionAuthorization: acl_ is not IBaseACL"
            );
        }
        _contractACL[contract_] = acl_;
        emit SetContractACL(contract_, acl_, msg.sender);
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        override
        returns (Type.CheckResult memory result_)
    {
        if (_contracts.contains(txData_.to)) {
            bytes4 selector = _getSelector(txData_.data);
            if (_isAllowedSelector(txData_.to, selector)) {
                result_.success = true;
                // further check acl if contract is authorized
                address acl = _contractACL[txData_.to];
                if (acl != address(0)) {
                    try BaseACL(acl).preCheck(txData_.from, txData_.to, txData_.data, txData_.value) returns (
                        Type.CheckResult memory aclCheckResult
                    ) {
                        return aclCheckResult;
                    } catch Error(string memory reason) {
                        result_.success = false;
                        result_.message = reason;
                    } catch (bytes memory reason) {
                        result_.success = false;
                        result_.message = string(reason);
                    }
                }
            } else {
                result_.success = false;
                result_.message = "FunctionAuthorization: not allowed function";
            }
        } else {
            result_.success = false;
            result_.message = "FunctionAuthorization: not allowed contract";
        }
        
    }

    function _isAllowedSelector(address target_, bytes4 selector_) internal view virtual returns (bool) {
        return _allowedContractToFunctions[target_].contains(selector_);
    }

    function _getSelector(bytes calldata data_) internal pure virtual returns (bytes4 selector_) {
        assembly {
            selector_ := calldataload(data_.offset)
        }
    }
}
