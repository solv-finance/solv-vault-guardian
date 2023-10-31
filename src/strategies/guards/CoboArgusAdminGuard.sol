// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import { FunctionGuard } from "../../common/FunctionGuard.sol";
import "forge-std/console.sol";

contract CoboArgusAdminGuard is FunctionGuard {

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

    constructor() {
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
    } 
}