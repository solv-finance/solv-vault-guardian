// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/ERC20TransferAuthorization.sol";
import "../../src/authorizations/gmxv2/GMXV2Authorization.sol";
import "../../src/authorizations/gmxv2/GMXV2AuthorizationACL.sol";

contract GMXV2AuthorizationTest is SolvVaultGuardianBaseTest {

    address internal constant gmxExchangeRouter = 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8;
    address internal constant gmxDepositVault = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
    address internal constant gmxWithdrawalVault = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

    address internal constant GMBTC = 0x47c031236e19d024b42f8AE6780E44A573170703;
    address internal constant GMETH = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;
    address internal constant GMARB = 0xC25cEf6061Cf5dE5eb761b50E4743c1F5D7E5407;

    GMXV2Authorization internal gmxV2Authorization;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardian(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        gmxV2Authorization = new GMXV2Authorization(address(_guardian), safeAccount, gmxExchangeRouter, gmxDepositVault, gmxWithdrawalVault);
    }

    function test_RevertWhenApproveTokenBeforeSettingAuthorization() public virtual {
        _revertMessage = "SolvVaultGuard: checkTransaction failed";
        _erc20Approve(USDC, governor, 1 ether);
        _erc20Approve(GMBTC, governor, 1 ether);
        _erc20Approve(GMETH, governor, 1 ether);
        _erc20Approve(GMARB, governor, 1 ether);
    }

    function test_RevertWhenTransferTokenBeforeSettingAuthorization() public virtual {
        _revertMessage = "SolvVaultGuard: checkTransaction failed";
        _erc20Transfer(USDC, governor, 1 ether);
        _erc20Transfer(GMBTC, governor, 1 ether);
        _erc20Transfer(GMETH, governor, 1 ether);
        _erc20Transfer(GMARB, governor, 1 ether);    
    }

    function test_approveTokenAfterSettingAuthorization() public virtual {
        vm.startPrank(governor);
        _addGMXV2Authorization();
        vm.stopPrank();

        _erc20Approve(USDC, governor, 1 ether);
        _erc20Approve(GMBTC, governor, 1 ether);
        _erc20Approve(GMETH, governor, 1 ether);
        _erc20Approve(GMARB, governor, 1 ether);
    }

    function test_BuyGMToken() public virtual {
        vm.startPrank(governor);
        _addGMXV2Authorization();
        vm.stopPrank();

        bytes[] memory multicallData = new bytes[](3);
        multicallData[0] = abi.encodeWithSignature("sendWnt(address,uint256)", 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 748000 gwei);
        multicallData[1] = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 1000000);
        multicallData[2] = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))", 
            CreateDepositParams(safeAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0)
        );
        bytes memory txData = abi.encodeWithSignature("multicall(bytes[])", multicallData);
        console.logBytes(txData);
        _callExecTransaction(gmxExchangeRouter, 748000 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenCall_SendWnt_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature("sendWnt(address,uint256)", 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 748000 gwei);
        uint256 value = 748000 gwei;
        _revertMessage = "SolvVaultGuard: checkTransaction failed";
        _callExecTransaction(gmxExchangeRouter, value, txData, Enum.Operation.Call);
    }

    function test_RevertWhenCall_SendTokens_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature("sendTokens(address,address,uint256)", USDC, 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55, 1000000);
        _revertMessage = "SolvVaultGuard: checkTransaction failed";
        _callExecTransaction(gmxExchangeRouter, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenCall_CreateDeposit_Directly() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "createDeposit((address,address,address,address,address,address,address[],address[],uint256,bool,uint256,uint256))", 
            safeAccount, address(0), address(0), GMBTC, WBTC, USDC, new address[](0), new address[](0), 0, false, 748000 gwei, 0
        );
        _revertMessage = "SolvVaultGuard: checkTransaction failed";
        _callExecTransaction(gmxExchangeRouter, 0, txData, Enum.Operation.Call);
    }

    function _addGMXV2Authorization() internal virtual {
        SolvVaultGuardian.Authorization memory auth = SolvVaultGuardian.Authorization({
            name: "GMXV2Authorization",
            executor: address(gmxV2Authorization),
            enabled: true
        });
        SolvVaultGuardian.Authorization[] memory auths = new SolvVaultGuardian.Authorization[](1);
        auths[0] = auth;
        _guardian.addAuthorizations(auths);
    }
    
}


// struct CreateDepositParams {
//     address receiver;
//     address callbackContract;
//     address uiFeeReceiver;
//     address market;
//     address initialLongToken;
//     address initialShortToken;
//     address[] longTokenSwapPath;
//     address[] shortTokenSwapPath;
//     uint256 minMarketTokens;
//     bool shouldUnwrapNativeToken;
//     uint256 executionFee;
//     uint256 callbackGasLimit;
// }

// struct CreateWithdrawalParams {
//     address receiver;
//     address callbackContract;
//     address uiFeeReceiver;
//     address market;
//     address[] longTokenSwapPath;
//     address[] shortTokenSwapPath;
//     uint256 minLongTokenAmount;
//     uint256 minShortTokenAmount;
//     bool shouldUnwrapNativeToken;
//     uint256 executionFee;
//     uint256 callbackGasLimit;
// }

