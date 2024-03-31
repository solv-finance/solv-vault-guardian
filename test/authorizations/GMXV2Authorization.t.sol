// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/gmxv2/GMXV2Authorization.sol";
import "../../src/authorizations/gmxv2/GMXV2AuthorizationACL.sol";

contract GMXV2AuthorizationTest is AuthorizationTestBase {

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
        
        address[] memory gmTokens = new address[](2);
        gmTokens[0] = GMBTC;
        gmTokens[1] = GMETH;

        GMXV2AuthorizationACL.CollateralPair[] memory gmPairs = new GMXV2AuthorizationACL.CollateralPair[](2);
        gmPairs[0] = GMXV2AuthorizationACL.CollateralPair(WBTC, USDC);
        gmPairs[1] = GMXV2AuthorizationACL.CollateralPair(WETH, USDC);

        _gmxV2Authorization = new GMXV2Authorization(
            address(_guardian), safeAccount, 
            GMX_V2_EXCHANGE_ROUTER, GMX_V2_DEPOSIT_VAULT, GMX_V2_WITHDRAWAL_VAULT,
            gmTokens, gmPairs
        );
        _authorization = _gmxV2Authorization;
    }

    function test_AuthorizationInitialStatus() public virtual {
        address acl = _gmxV2Authorization.getACLByContract(GMX_V2_EXCHANGE_ROUTER);
        assertNotEq(acl, address(0));
        assertTrue(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMBTC));
        assertTrue(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMETH));
        assertFalse(GMXV2AuthorizationACL(acl).isPoolAuthorized(GMARB));
        assertFalse(GMXV2AuthorizationACL(acl).isPoolAuthorized(WBTC));
        assertFalse(GMXV2AuthorizationACL(acl).isPoolAuthorized(USDC));
    }

    function test_BuyGMToken() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Type.CheckResult(true, ""));
    }

    function test_SellGMToken() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenMulticallWithInvalidSelector() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[2] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "not deposit or withdraw operation")
        );
    }

    function test_RevertWhenDeposit_NotSendWnt() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[0] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, GMX_V2_DEPOSIT_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "sendWnt error")
        );
    }

    function test_RevertWhenDeposit_SendWntToInvalidAddress() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", permissionlessAccount, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid wnt receiver")
        );
    }

    function test_RevertWhenDeposit_SendWntInExcess() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748001 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid wnt amount")
        );
    }

    function test_RevertWhenDeposit_NotSendToken_InNotEthCase() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_DEPOSIT_VAULT, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 1496000 gwei, txData, 
            Type.CheckResult(false, "invalid wnt amount")
        );
    }

    function test_RevertWhenDeposit_SendUnauthorizedToken() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", WETH, GMX_V2_DEPOSIT_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "token not authorized")
        );
    }

    function test_RevertWhenDeposit_SendTokenToInvalidAddress() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, permissionlessAccount, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid token receiver")
        );
    }

    function test_RevertWhenDeposit_CreateWithUnauthorizedPool() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(safeAccount, address(0), address(0), GMSOL, WSOL, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "pool not authorized")
        );
    }

    function test_RevertWhenDeposit_CreateWithInvalidGmTokenReceiver() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(permissionlessAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid deposit receiver")
        );
    }

    function test_RevertWhenDeposit_CreateWithInvalidFallbackContract() public virtual {
        bytes[] memory multicallData = _getDefaultDepositData();
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            CreateDepositParams(safeAccount, address(1), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(
            GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "deposit callback not allowed")
        );
    }


    function test_RevertWhenWithdraw_NotSendWnt() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[0] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMBTC, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "sendWnt error")
        );
    }

    function test_RevertWhenWithdraw_SendWntToInvalidAddress() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", permissionlessAccount, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid wnt receiver")
        );
    }

    function test_RevertWhenWithdraw_SendWntInExcess() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_WITHDRAWAL_VAULT, 748001 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid wnt amount")
        );
    }

    function test_RevertWhenWithdraw_NotSendToken() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendWnt(address,uint256)", GMX_V2_WITHDRAWAL_VAULT, 748000 gwei);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 1496000 gwei, txData, 
            Type.CheckResult(false, "invalid wnt amount")
        );
    }

    function test_RevertWhenWithdraw_SendIncorrectToken() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMETH, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "GM token not matches")
        );
    }

    function test_RevertWhenWithdraw_SendTokenToInvalidAddress() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMBTC, permissionlessAccount, 1 ether);
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid token receiver")
        );
    }

    function test_RevertWhenWithdraw_CreateWithUnauthorizedPool() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", GMSOL, GMX_V2_WITHDRAWAL_VAULT, 1 ether);
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(safeAccount, address(0), address(0), GMSOL, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "pool not authorized")
        );
    }

    function test_RevertWhenWithdraw_CreateWithInvalidTokenReceiver() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(permissionlessAccount, address(0), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "invalid withdrawal receiver")
        );
    }

    function test_RevertWhenWithdraw_CreateWithInvalidFallbackContract() public virtual {
        bytes[] memory multicallData = _getDefaultWithdrawData();
        multicallData[2] = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            CreateWithdrawalParams(safeAccount, address(1), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 748000 gwei, txData, 
            Type.CheckResult(false, "withdrawal callback not allowed")
        );
    }


    function test_RevertWhenCall_SendWnt_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "sendWnt(address,uint256)", 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 748000 gwei
        );
        uint256 value = 748000 gwei;
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, value, txData, 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenCall_SendTokens_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "sendTokens(address,address,uint256)", USDC, 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 1000000
        );
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 0, txData, 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenCall_CreateDeposit_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))",
            safeAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0
        );
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 0, txData, 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenCall_CreateWithdrawal_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "createWithdrawal((address,address,address,address,address[],address[],uint256,uint256,bool,uint256,uint256))",
            safeAccount, address(0), address(0), GMBTC, new address[](0), new address[](0), 0, 0, false, 748000 gwei, 0
        );
        _checkFromAuthorization(GMX_V2_EXCHANGE_ROUTER, 0, txData, 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }
    

    function test_AddGmxPool() public virtual {
        GMXV2AuthorizationACLMock acl = new GMXV2AuthorizationACLMock(
            address(_guardian), safeAccount, 
            GMX_V2_EXCHANGE_ROUTER, GMX_V2_DEPOSIT_VAULT, GMX_V2_WITHDRAWAL_VAULT,
            new address[](0), new GMXV2AuthorizationACL.CollateralPair[](0)
        );

        GMXV2AuthorizationACL.CollateralPair memory gmPair = GMXV2AuthorizationACL.CollateralPair({
            longCollateral: WBTC,
            shortCollateral: USDC
        });
        acl.addGmxPool(GMBTC, gmPair);
    }

    function test_RevertWhenAddGmxPoolWithInvalidTokenAddress() public virtual {
        GMXV2AuthorizationACLMock acl = new GMXV2AuthorizationACLMock(
            address(_guardian), safeAccount, 
            GMX_V2_EXCHANGE_ROUTER, GMX_V2_DEPOSIT_VAULT, GMX_V2_WITHDRAWAL_VAULT,
            new address[](0), new GMXV2AuthorizationACL.CollateralPair[](0)
        );

        vm.expectRevert("invalid token addresses");
        acl.addGmxPool(address(0), GMXV2AuthorizationACL.CollateralPair({
            longCollateral: WBTC,
            shortCollateral: USDC
        }));

        vm.expectRevert("invalid token addresses");
        acl.addGmxPool(GMBTC, GMXV2AuthorizationACL.CollateralPair({
            longCollateral: address(0),
            shortCollateral: USDC
        }));

        vm.expectRevert("invalid token addresses");
        acl.addGmxPool(GMBTC, GMXV2AuthorizationACL.CollateralPair({
            longCollateral: WBTC,
            shortCollateral: address(0)
        }));
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

contract GMXV2AuthorizationACLMock is GMXV2AuthorizationACL {
    constructor(
        address caller_,
        address safeAccount_,
        address exchangeRouter_,
        address depositVault_,
        address withdrawalVault_,
        address[] memory gmTokens_,
        CollateralPair[] memory collateralPairs_
    ) 
        GMXV2AuthorizationACL(
            caller_, safeAccount_, exchangeRouter_, 
            depositVault_, withdrawalVault_, gmTokens_, collateralPairs_
        )
    {}

    function addGmxPool(address gmToken_, CollateralPair memory collateralPair_) external virtual {
        _addGmxPool(gmToken_, collateralPair_);
    }
}
