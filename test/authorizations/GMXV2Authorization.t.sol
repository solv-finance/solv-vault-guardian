// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/gmxv2/GMXV2Authorization.sol";
import "../../src/authorizations/gmxv2/GMXV2AuthorizationACL.sol";

contract GMXV2AuthorizationTest is SolvVaultGuardianBaseTest {

    address internal constant GMX_V2_EXCHANGE_ROUTER = 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8;
    address internal constant GMX_V2_DEPOSIT_VAULT = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
    address internal constant GMX_V2_WITHDRAWAL_VAULT = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

    address internal constant GMBTC = 0x47c031236e19d024b42f8AE6780E44A573170703;
    address internal constant GMETH = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;
    address internal constant GMARB = 0xC25cEf6061Cf5dE5eb761b50E4743c1F5D7E5407;
    address internal constant GMSOL = 0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9;  // not allowed

    GMXV2Authorization internal _gmxV2Authorization;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        _gmxV2Authorization = new GMXV2Authorization(
            address(_guardian), safeAccount, GMX_V2_EXCHANGE_ROUTER, GMX_V2_DEPOSIT_VAULT, GMX_V2_WITHDRAWAL_VAULT
        );
    }

    function test_AuthorizationInitialStatus() public virtual {
        address acl = _gmxV2Authorization.getACLByContract(GMX_V2_EXCHANGE_ROUTER);
        assertNotEq(acl, address(0));
        assertTrue(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMBTC));
        assertTrue(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMETH));
        assertTrue(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMARB));
        assertFalse(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMSOL));
        assertFalse(GMXV2AuthorizationACL(acl).isPoolAuthorized(USDC));
    }

    function test_GuardianInitialStatus() public virtual {
        _addGMXV2Authorization();
        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 1);
        assertEq(toAddresses[0], GMX_V2_EXCHANGE_ROUTER);
    }

    function test_BuyGMToken() public virtual {
        _addGMXV2Authorization();
        bytes[] memory multicallData = _getDefaultDepositData();
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_SellGMToken() public virtual {
        _addGMXV2Authorization();
        bytes[] memory multicallData = _getDefaultWithdrawData();
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenMulticallWithInvalidSelector() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "not deposit or withdraw operation";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[2] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_NotSendWnt() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "sendWnt error";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[0] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, GMX_V2_DEPOSIT_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_SendWntToInvalidAddress() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid wnt receiver";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", permissionlessAccount, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_SendWntInExcess() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid wnt amount";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748001 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_NotSendToken_InNotEthCase() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid wnt amount";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 1496000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_SendUnauthorizedToken() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "token not authorized";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", WETH, GMX_V2_DEPOSIT_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_SendTokenToInvalidAddress() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid token receiver";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, permissionlessAccount, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_CreateWithUnauthorizedPool() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "pool not authorized";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(safeAccount, address(0), address(0), GMSOL, WSOL, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_CreateWithInvalidGmTokenReceiver() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid deposit receiver";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(permissionlessAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDeposit_CreateWithInvalidFallbackContract() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "deposit callback not allowed";
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(safeAccount, address(1), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }


    function test_RevertWhenWithdraw_NotSendWnt() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "sendWnt error";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[0] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMBTC, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_SendWntToInvalidAddress() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid wnt receiver";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", permissionlessAccount, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_SendWntInExcess() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid wnt amount";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_WITHDRAWAL_VAULT, 748001 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_NotSendToken() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid wnt amount";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_WITHDRAWAL_VAULT, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 1496000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_SendIncorrectToken() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "GM token not matches";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMETH, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_SendTokenToInvalidAddress() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid token receiver";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMBTC, permissionlessAccount, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_CreateWithUnauthorizedPool() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "pool not authorized";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMSOL, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(safeAccount, address(0), address(0), GMSOL, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_CreateWithInvalidTokenReceiver() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "invalid withdrawal receiver";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(permissionlessAccount, address(0), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdraw_CreateWithInvalidFallbackContract() public virtual {
        _addGMXV2Authorization();
        _revertMessage = "withdrawal callback not allowed";
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(safeAccount, address(1), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Enum.Operation.Call);
    }


    function test_RevertWhenCall_SendWnt_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "sendWnt(address,uint256)", 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 748000 gwei
        );
        uint256 value = 748000 gwei;
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, value, txData, Enum.Operation.Call);
    }

    function test_RevertWhenCall_SendTokens_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "sendTokens(address,address,uint256)", USDC, 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 1000000
        );
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenCall_CreateDeposit_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            safeAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0
        );
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenCall_CreateWithdrawal_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            safeAccount, address(0), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0
        );
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(GMX_V2_EXCHANGE_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function _addGMXV2Authorization() internal virtual {
        vm.startPrank(governor);
        _guardian.setAuthorization(GMX_V2_EXCHANGE_ROUTER, address(_gmxV2Authorization));
        vm.stopPrank();
    }

    function _getDefaultDepositData() internal view virtual returns (bytes[] memory multicallData) {
        multicallData = new bytes[](3);
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748000 gwei);
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, GMX_V2_DEPOSIT_VAULT, 1 ether);
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(safeAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
    }

    function _getDefaultWithdrawData() internal view virtual returns (bytes[] memory multicallData) {
        multicallData = new bytes[](3);
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_WITHDRAWAL_VAULT, 748000 gwei);
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMBTC, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(safeAccount, address(0), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
    }

}
