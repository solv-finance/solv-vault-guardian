// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {FunctionAuthorization} from "../common/FunctionAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

contract CoboArgusAdminAuthorization is FunctionAuthorization {
    string public constant NAME = "SolvVaultGuard_CoboArgusAdminAuthorization";
    int256 public constant VERSION = 1;

    /**
     * On Arbitrum
     * argusAccountHelper : 0x58D3a5586A8083A207A01F21B971157921744807
     * argusFlatRoleManager : 0x80346Efdc8957843A472e5fdaD12Ea4fD340A845
     * argusFarmingBaseAcl : 0xFd11981Da6af3142555e3c8B60d868C7D7eE1963
     */
    constructor(
        address safeMultiSendContract_,
        address caller_,
        address argusAccountHelper_,
        address argusFlatRoleManager_,
        address argusFarmingBaseAcl_
    ) FunctionAuthorization(safeMultiSendContract_, caller_, Governable(caller_).governor()) {
        string[] memory argusAccountHelperFuncs = new string[](6);
        argusAccountHelperFuncs[0] = "initArgus(address,bytes32)";
        argusAccountHelperFuncs[1] = "createAuthorizer(address,address,bytes32,bytes32)";
        argusAccountHelperFuncs[2] = "addAuthorizer(address,address,bool,bytes32[])";
        argusAccountHelperFuncs[3] = "addFuncAuthorizer(address,address,bool,bytes32[],address[],string[][],bytes32)";
        argusAccountHelperFuncs[4] = "grantRoles(address,bytes32[],address[])";
        argusAccountHelperFuncs[5] = "revokeRoles(address,bytes32[],address[])";
        _addContractFuncs(argusAccountHelper_, argusAccountHelperFuncs);

        string[] memory argusFlatRoleManagerFuncs = new string[](1);
        argusFlatRoleManagerFuncs[0] = "addRoles(bytes32[])";
        _addContractFuncs(argusFlatRoleManager_, argusFlatRoleManagerFuncs);

        string[] memory argusFarmingBaseAclFuncs = new string[](1);
        argusFarmingBaseAclFuncs[0] = "addPoolAddresses(address[])";
        _addContractFuncs(argusFarmingBaseAcl_, argusFarmingBaseAclFuncs);
    }
}
