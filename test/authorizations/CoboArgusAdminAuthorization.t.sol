// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/CoboArgusAdminAuthorization.sol";

contract CoboArgusAdminAuthorizationTest is AuthorizationTestBase {

    address internal constant ARGUS_ACCOUNT_HELPER = 0x58D3a5586A8083A207A01F21B971157921744807;
    address internal constant ARGUS_FLAT_ROLE_MANAGER = 0x80346Efdc8957843A472e5fdaD12Ea4fD340A845;
    address internal constant ARGUS_FARMING_BASE_ACL = 0xFd11981Da6af3142555e3c8B60d868C7D7eE1963;

    address internal constant COBO_FACTORY = 0xC0B00000e19D71fA50a9BB1fcaC2eC92fac9549C;
    address internal constant COBO_ACCOUNT = 0xbc3Fe534809634Cd805067B0fA15Fb8F55Dcf161;
    address internal constant COBO_AUTHORIZATION = 0xdDdcB7e2964755A4c80299B9aDC9dC2fE4699520;

    CoboArgusAdminAuthorization internal _coboArgusAdminAuthorization;

    function setUp() public virtual override {
        super.setUp();
        _authorization = new CoboArgusAdminAuthorization(
            address(_guardian), ARGUS_ACCOUNT_HELPER, ARGUS_FLAT_ROLE_MANAGER, ARGUS_FARMING_BASE_ACL
        );
    }

    function test_InitArgus() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "initArgus(address,bytes32)", 
            COBO_FACTORY, keccak256(abi.encodePacked("salt"))
        );
        _checkFromAuthorization(ARGUS_ACCOUNT_HELPER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_CreateAuthorizer() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "createAuthorizer(address,address,bytes32,bytes32)", 
            COBO_FACTORY, COBO_ACCOUNT, keccak256(abi.encodePacked("name")), keccak256(abi.encodePacked("tag"))
        );
        _checkFromAuthorization(ARGUS_ACCOUNT_HELPER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_AddAuthorizer() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "addAuthorizer(address,address,bool,bytes32[])", 
            COBO_ACCOUNT, COBO_AUTHORIZATION, false, new bytes32[](0)
        );
        _checkFromAuthorization(ARGUS_ACCOUNT_HELPER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_AddFuncAuthorizer() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "addFuncAuthorizer(address,address,bool,bytes32[],address[],string[][],bytes32)", 
            COBO_FACTORY, COBO_ACCOUNT, false, new bytes32[](0), new address[](0), new string[][](0), 
            keccak256(abi.encodePacked("tag"))
        );
        _checkFromAuthorization(ARGUS_ACCOUNT_HELPER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_GrantRoles() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "grantRoles(address,bytes32[],address[])", 
            COBO_ACCOUNT, new bytes32[](0), new address[](0)
        );
        _checkFromAuthorization(ARGUS_ACCOUNT_HELPER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevokeRoles() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "revokeRoles(address,bytes32[],address[])", 
            COBO_ACCOUNT, new bytes32[](0), new address[](0)
        );
        _checkFromAuthorization(ARGUS_ACCOUNT_HELPER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_AddRoles() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "addRoles(bytes32[])", 
            new bytes32[](0)
        );
        _checkFromAuthorization(ARGUS_FLAT_ROLE_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_AddPoolAddresses() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "addPoolAddresses(address[])", 
            new address[](0)
        );
        _checkFromAuthorization(ARGUS_FARMING_BASE_ACL, 0, txData, Type.CheckResult(true, ""));
    }

}
