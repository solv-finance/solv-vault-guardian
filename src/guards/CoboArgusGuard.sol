// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/console.sol";
import {FunctionGuard} from "../common/FunctionGuard.sol";

contract CoboArgusGuard is FunctionGuard {
    address public constant SAFE_MULTI_SEND_CONTRACT = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;
    string public constant SAFE_MULITSEND_FUNC_MULTI_SEND = "multiSend(bytes)";

    address public constant ARGUS_CONTRACTS_ACCOUNT_HELPER = 0x58D3a5586A8083A207A01F21B971157921744807;
    string public constant ARGUS_ACCOUNT_HELPER_FUNC_INIT_ARGUS = "initArgus(address,bytes32)";
    string public constant ARGUS_ACCOUNT_HELPER_FUNC_CREATE_AUTHORIZER = "createAuthorizer(address,address,bytes32,bytes32)";
    string public constant ARGUS_ACCOUNT_HELPER_FUNC_ADD_AUTHORIZER = "addAuthorizer(address,address,bool,bytes32[])";
    string public constant ARGUS_ACCOUNT_HELPER_FUNC_ADD_FUNC_AUTHORIZER = "addFuncAuthorizer(address,address,bool,bytes32[],address[],string[][],bytes32)";
    string public constant ARGUS_ACCOUNT_HELPER_FUNC_GRANT_ROLES = "grantRoles(address,bytes32[],address[])";
    string public constant ARGUS_ACCOUNT_HELPER_FUNC_REVOKE_ROLES = "revokeRoles(address,bytes32[],address[])";

    address public constant ARGUS_CONTRACTS_FLAT_ROLE_MANAGER = 0x71D7e97778DEC858D01b00dC2CB76491B7588C4b;
    string public constant ARGUS_FLAT_ROLE_MANAGER_FUNC_ADD_ROLE = "addRoles(bytes32[])";

    address public constant ARGUS_CONTRACTS_FARMING_BASE_ACL = 0xFd11981Da6af3142555e3c8B60d868C7D7eE1963;
    string public constant ARGUS_FARMING_BASE_ACL_FUNC_ADD_POOL_ADDRESS= "addPoolAddresses(address[])";

    string public constant ERC20_APPROVE_FUNC = "approve(address,uint256)";

    constructor(address[] memory tokenApproval_) {
        string[] memory safeMultiSendFuncs = new string[](1);
        safeMultiSendFuncs[0] = SAFE_MULITSEND_FUNC_MULTI_SEND;
        _addContractFuncs(SAFE_MULTI_SEND_CONTRACT, safeMultiSendFuncs);

        string[] memory argusAccountHelperFuncs = new string[](6);
        argusAccountHelperFuncs[0] = ARGUS_ACCOUNT_HELPER_FUNC_INIT_ARGUS;
        argusAccountHelperFuncs[1] = ARGUS_ACCOUNT_HELPER_FUNC_CREATE_AUTHORIZER;
        argusAccountHelperFuncs[2] = ARGUS_ACCOUNT_HELPER_FUNC_ADD_AUTHORIZER;
        argusAccountHelperFuncs[3] = ARGUS_ACCOUNT_HELPER_FUNC_ADD_FUNC_AUTHORIZER;
        argusAccountHelperFuncs[4] = ARGUS_ACCOUNT_HELPER_FUNC_GRANT_ROLES;
        argusAccountHelperFuncs[5] = ARGUS_ACCOUNT_HELPER_FUNC_REVOKE_ROLES;
        _addContractFuncs(ARGUS_CONTRACTS_ACCOUNT_HELPER, argusAccountHelperFuncs);

        string[] memory argusFlatRoleManagerFuncs = new string[](1);
        argusFlatRoleManagerFuncs[0] = ARGUS_FLAT_ROLE_MANAGER_FUNC_ADD_ROLE;
        _addContractFuncs(ARGUS_CONTRACTS_FLAT_ROLE_MANAGER, argusFlatRoleManagerFuncs);

        string[] memory argusFarmingBaseAclFuncs = new string[](1);
        argusFarmingBaseAclFuncs[0] = ARGUS_FARMING_BASE_ACL_FUNC_ADD_POOL_ADDRESS;
        _addContractFuncs(ARGUS_CONTRACTS_FARMING_BASE_ACL, argusFarmingBaseAclFuncs);

        string[] memory approveTokensFuncs = new string[](1);
        approveTokensFuncs[0] = ERC20_APPROVE_FUNC;
        for (uint256 i = 0; i < tokenApproval_.length; i++) {
            _addContractFuncs(tokenApproval_[i], approveTokensFuncs);
        }
    } 

    function _checkTransactionWithRecursion(address to_, bytes calldata data_) internal view 
        virtual override returns (CheckResult memory result_) {
        bytes4 selector = _getSelector(data_);
        console.logBytes4(selector);

        if (selector == bytes4(keccak256(bytes(SAFE_MULITSEND_FUNC_MULTI_SEND)))) {
            result_ = _checkMultiSend(data_);
        
        } else {
            result_ = super._checkTransactionWithRecursion(to_, data_);
        }
    }

    function _checkMultiSend(bytes calldata transactions_) internal view returns (CheckResult memory result_) {
        uint256 offset = 4 + 32;
        uint256 multiSendDataLength = uint256(bytes32(transactions_[offset:offset+32]));
        bytes calldata multiSendData = transactions_[offset+32:offset+32+multiSendDataLength];
        uint256 startIndex = 0;
        while (startIndex < multiSendData.length) {
            (address to, bytes calldata data, uint256 endIndex) = _unpackMultiSend(multiSendData, startIndex);
            if (to != address(0)) {
                result_ = _checkTransactionWithRecursion(to, data);
                if (!result_.success) {
                    return result_;
                }
            }
           
            startIndex = endIndex;
        }

        result_.success = true;
    }

    function _unpackMultiSend(bytes calldata transactions_, uint256 startIndex_) internal pure 
        returns( address to_, bytes calldata data_, uint256 endIndex_) {
        uint256 offset = 0; 
        uint256 length = 1;
        offset += length; 

        //address 20 bytes
        length = 20;
        to_ = address(bytes20(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //value 32 bytes
        length = 32;
        offset += length;

        //datalength 32 bytes
        length = 32;
        uint256 dataLength = uint256(bytes32(transactions_[startIndex_ + offset:startIndex_ + offset + length]));
        offset += length;

        //data
        data_ = transactions_[startIndex_ + offset:startIndex_ + offset + dataLength];

        endIndex_ = startIndex_ + offset + dataLength;
        return (to_, data_, endIndex_);
    }
}