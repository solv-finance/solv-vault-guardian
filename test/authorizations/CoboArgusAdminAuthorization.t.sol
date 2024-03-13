// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../integration/SolvVaultGuardianTestBase.sol";
import "../../src/authorizations/CoboArgusAdminAuthorization.sol";

// contract CoboArgusAdminAuthorizationTest is SolvVaultGuardianTestBase {

    // address internal constant ARGUS_ACCOUNT_HELPER = 0x58D3a5586A8083A207A01F21B971157921744807;
    // // address internal constant ARGUS_FLAT_ROLE_MANAGER = 0x80346Efdc8957843A472e5fdaD12Ea4fD340A845;
    // // address internal constant ARGUS_FARMING_BASE_ACL = 0xFd11981Da6af3142555e3c8B60d868C7D7eE1963;

    // address internal constant COBO_FACTORY = 0xC0B00000e19D71fA50a9BB1fcaC2eC92fac9549C;

    // address internal _coboSafeAccount;
    // address internal _coboRoleManager;
    // address internal _coboFarmingStrategyAuthorizer;

    // CoboArgusAdminAuthorization internal _coboArgusAdminAuthorization;

    // function setUp() public virtual override {
    //     super.setUp();
    //     _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
    //     super._setSafeGuard();

    //     _initArgusWithSafe(COBO_FACTORY, 0x15f043cfc880b3e17ffd15e6d0a4dc17a951a863320000000000000000000000);
    //     _coboSafeAccount = _getModuleAddress(safeAccount);
    //     _coboRoleManager = _getRoleManager(_coboSafeAccount);
    //     // _coboArgusAdminAuthorization = new CoboArgusAdminAuthorization(
    //     //     SAFE_MULTI_SEND_CONTRACT, address(_guardian), ARGUS_ACCOUNT_HELPER, ARGUS_FLAT_ROLE_MANAGER, ARGUS_FARMING_BASE_ACL
    //     // );
    // }

    // function test_ArgusRoleOperations() public virtual {
    //     _addCoboArgusAdminAuthorization();
    //     _initArgusWithSafe(COBO_FACTORY, 0x15f043cfc880b3e17ffd15e6d0a4dc17a951a863320000000000000000000000);
    //     _coboSafeAccount = _getModuleAddress(safeAccount);
    //     _coboRoleManager = _getRoleManager(_coboSafeAccount);

    //     bytes32[] memory roles = new bytes32[](1);
    //     roles[0] = 0x474d582d54726164657200000000000000000000000000000000000000000000;
    //     _addRolesWithSafe(roles);

    //     address[] memory delegates = new address[](1);
    //     delegates[0] = ownerOfSafe;
    //     _grantRolesWithSafe(_coboSafeAccount, roles, delegates);
    //     _revokeRolesWithSafe(_coboSafeAccount, roles, delegates);
    // }

    // // function test_ArgusOpereations() public virtual {
    // //     _addCoboArgusAdminAuthorization();
    // //     _initArgusWithSafe(COBO_FACTORY, 0x15f043cfc880b3e17ffd15e6d0a4dc17a951a863320000000000000000000000);
    // //     _coboSafeAccount = _getModuleAddress(safeAccount);
    // //     _coboRoleManager = _getRoleManager(_coboSafeAccount);

    // //     bytes32[] memory roles = new bytes32[](1);
    // //     roles[0] = 0x474d582d54726164657200000000000000000000000000000000000000000000;
    // //     _addRolesWithSafe(roles);

    // //     address[] memory delegates = new address[](1);
    // //     delegates[0] = ownerOfSafe;
    // //     _grantRolesWithSafe(_coboSafeAccount, roles, delegates);
    // //     // _revokeRolesWithSafe(_coboSafeAccount, roles, delegates);

    // //     _createAuthorizerWithSafe(COBO_FACTORY, _coboSafeAccount, 0x476d7845786368616e6765526f75746572417574686f72697a65720000000000, 0x4172677573474d5856322d474d5f416c74436f696e0000000000000000000000);
    // //     address authorizerAddress = _getAuthorizerAddress(safeAccount, 0x476d7845786368616e6765526f75746572417574686f72697a65720000000000, 0x4172677573474d5856322d474d5f416c74436f696e0000000000000000000000);
    // //     address[] memory poolAddresses = new address[](2);
    // //     poolAddresses[0] = 0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9;
    // //     poolAddresses[1] = 0xc7Abb2C5f3BF3CEB389dF0Eecd6120D451170B50;
    // //     _addPoolAddressesWithSafe(authorizerAddress, poolAddresses);
    // //     _addAuthorizerWithSafe(_coboSafeAccount, authorizerAddress, false, roles);
    // // }

    // function _addCoboArgusAdminAuthorization() internal virtual {
    //     SolvVaultGuardianForSafe13.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](1);
    //     auths[0] = SolvVaultGuardianBase.Authorization("CoboArgusAdminAuthorization", address(_coboArgusAdminAuthorization), true);

    //     vm.startPrank(governor);
    //     _guardian.addAuthorizations(auths);
    //     vm.stopPrank();
    // }

    // function _initArgusWithSafe(address factory, bytes32 coboSafeAccountSalt) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("initArgus(address,bytes32)")), factory, coboSafeAccountSalt);
    //     _callExecTransaction(ARGUS_ACCOUNT_HELPER, 0, data, Enum.Operation.DelegateCall);
    // }

    // function _createAuthorizerWithSafe(address factory, address coboSafeAddress, bytes32 authorizerName, bytes32 tag) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("createAuthorizer(address,address,bytes32,bytes32)")), factory, coboSafeAddress, authorizerName, tag);
    //     _callExecTransaction(ARGUS_ACCOUNT_HELPER, 0, data, Enum.Operation.DelegateCall);
    // }

    // function _addAuthorizerWithSafe(address coboSafeAddress, address authorizerAddress, bool isDelegateCall, bytes32[] memory roles) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("addAuthorizer(address,address,bool,bytes32[])")), coboSafeAddress, authorizerAddress, isDelegateCall, roles);
    //     _callExecTransaction(ARGUS_ACCOUNT_HELPER, 0, data, Enum.Operation.DelegateCall);
    // }

    // function _addFuncAuthorizerWithSafe(address factory, address coboSafeAddress, bool isDelegateCall, bytes32[] memory roles, address[] memory contracts, string[][] memory funcLists, bytes32 tag) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("addFuncAuthorizer(address,address,bool,bytes32[],address[],string[][],bytes32)")), factory, coboSafeAddress, isDelegateCall, roles, contracts, funcLists, tag);
    //     _callExecTransaction(ARGUS_ACCOUNT_HELPER, 0, data, Enum.Operation.DelegateCall);
    // }

    // function _grantRolesWithSafe(address coboSafeAddress, bytes32[] memory roles, address[] memory delegates) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("grantRoles(address,bytes32[],address[])")), coboSafeAddress, roles, delegates);
    //     _callExecTransaction(ARGUS_ACCOUNT_HELPER, 0, data, Enum.Operation.DelegateCall);
    // }

    // function _revokeRolesWithSafe(address coboSafeAddress, bytes32[] memory roles, address[] memory delegates) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("revokeRoles(address,bytes32[],address[])")), coboSafeAddress, roles, delegates);
    //     _callExecTransaction(ARGUS_ACCOUNT_HELPER, 0, data, Enum.Operation.DelegateCall);
    // }

    // function _addRolesWithSafe(bytes32[] memory roles) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("addRoles(bytes32[])")), roles);
    //     _callExecTransaction(_coboRoleManager, 0, data, Enum.Operation.Call);
    // }

    // function _addPoolAddressesWithSafe(address authorizer, address[] memory poolAddresses) internal {
    //     bytes memory data = abi.encodeWithSelector(bytes4(keccak256("addPoolAddresses(address[])")), poolAddresses);
    //     _callExecTransaction(authorizer, 0, data, Enum.Operation.Call);
    // }

    // function _getModuleAddress(address safeAccount) internal view returns (address) {
    //     bytes memory data = abi.encodeWithSignature("getModulesPaginated(address,uint256)", address(1), 1);
    //     (, bytes memory returnData) = safeAccount.staticcall(data);
    //     (address[] memory modules, ) = abi.decode(returnData, (address[], address));
    //     return modules[0];
    // }

    // function _getRoleManager(address coboSafeAccount) internal view returns (address roleManager) {
    //     bytes memory data = abi.encodeWithSignature("roleManager()");
    //     (, bytes memory returnData) = coboSafeAccount.staticcall(data);
    //     (roleManager) = abi.decode(returnData, (address));
    // }

    // function _getRoleManagerOwner(address roleManager) internal view returns (address owner) {
    //     bytes memory data = abi.encodeWithSignature("owner()");
    //     (, bytes memory returnData) = roleManager.staticcall(data);
    //     (owner) = abi.decode(returnData, (address));
    // }

    // function _getAuthorizerAddress(address safeAccount, bytes32 name, bytes32 salt) internal view returns (address instance) {
    //     bytes memory data = abi.encodeWithSignature("getCreate2Address(address,bytes32,bytes32)", safeAccount, name, salt);
    //     (, bytes memory returnData) = COBO_FACTORY.staticcall(data);
    //     (instance) = abi.decode(returnData, (address));
    // }

// }
