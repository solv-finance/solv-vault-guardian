// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/merlinswap/MerlinSwapLiquidityManagerAuthorization.sol";
import "../../src/authorizations/merlinswap/MerlinSwapLiquidityManagerAuthorizationACL.sol";

contract MerlinSwapLiquidityManagerAuthorizationTest is AuthorizationTestBase {

    address internal constant LIQUIDITY_MANAGER = 0xBF55ef05412f1528DbD96ED9E7181f87d8C9F453;

    function setUp() public override {
        super.setUp();

        address[] memory tokenWhitelist = new address[](3);
        tokenWhitelist[0] = WETH;
        tokenWhitelist[1] = WBTC;
        tokenWhitelist[2] = USDT;
        _authorization = new MerlinSwapLiquidityManagerAuthorization(address(_guardian), safeAccount, LIQUIDITY_MANAGER, tokenWhitelist);
    }

    function test_AuthorizationInitialStatus() public {
        address acl = _authorization.getACLByContract(LIQUIDITY_MANAGER);
        assertNotEq(acl, address(0));
    }

    function test_Mint() public {
        bytes memory txData = abi.encodeWithSignature(
            "mint((address,address,address,uint24,int24,int24,uint128,uint128,uint128,uint128,uint256))", 
            ILiquidityManager.MintParam(safeAccount, WBTC, USDT, uint24(500), int24(800001), int24(800001), 1 ether, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_AddLiquidity() public {
        bytes memory txData = abi.encodeWithSignature(
            "addLiquidity((uint256,uint128,uint128,uint128,uint128,uint256))", 
            ILiquidityManager.AddLiquidityParam(1, 1 ether, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_DecLiquidity() public {
        bytes memory txData = abi.encodeWithSignature(
            "decLiquidity(uint256,uint128,uint256,uint256,uint256)", 
            1, 1 ether, 1 ether, 1 ether, block.timestamp + 300
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Collect() public {
        bytes memory txData = abi.encodeWithSignature(
            "collect(address,uint256,uint128,uint128)", 
            safeAccount, 1, 1 ether, 1 ether
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_UnwrapWETH9() public {
        bytes memory txData = abi.encodeWithSignature(
            "unwrapWETH9(uint256,address)", 
            1 ether, safeAccount
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SweepToken() public {
        bytes memory txData = abi.encodeWithSignature(
            "sweepToken(address,uint256,address)", 
            WBTC, 1 ether, safeAccount
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RefundETH() public {
        bytes memory txData = abi.encodeWithSignature("refundETH()");
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Burn() public {
        bytes memory txData = abi.encodeWithSignature("burn(uint256)", 1);
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenMintWithInvalidTokenX() public {
        bytes memory txData = abi.encodeWithSignature(
            "mint((address,address,address,uint24,int24,int24,uint128,uint128,uint128,uint128,uint256))", 
            ILiquidityManager.MintParam(safeAccount, USDC, USDT, uint24(500), int24(800001), int24(800001), 1 ether, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: tokenX not allowed"));
    }

    function test_RevertWhenMintWithInvalidTokenY() public {
        bytes memory txData = abi.encodeWithSignature(
            "mint((address,address,address,uint24,int24,int24,uint128,uint128,uint128,uint128,uint256))", 
            ILiquidityManager.MintParam(safeAccount, WBTC, USDC, uint24(500), int24(800001), int24(800001), 1 ether, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: tokenY not allowed"));
    }

    function test_RevertWhenMintWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "mint((address,address,address,uint24,int24,int24,uint128,uint128,uint128,uint128,uint256))", 
            ILiquidityManager.MintParam(permissionlessAccount, WBTC, USDT, uint24(500), int24(800001), int24(800001), 1 ether, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: recipient(miner) not allowed"));
    }

    function test_RevertWhenCollectWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "collect(address,uint256,uint128,uint128)", 
            permissionlessAccount, 1, 1 ether, 1 ether
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: recipient not allowed"));
    }

    function test_RevertWhenUnwrapWETH9WithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "unwrapWETH9(uint256,address)", 
            1 ether, permissionlessAccount
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: recipient not allowed"));
    }

    function test_RevertWhenSweepTokenWithInvalidToken() public {
        bytes memory txData = abi.encodeWithSignature(
            "sweepToken(address,uint256,address)", 
            USDC, 1 ether, safeAccount
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: token not allowed"));
    }

    function test_RevertWhenSweepTokenWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "sweepToken(address,uint256,address)", 
            WBTC, 1 ether, permissionlessAccount
        );
        _checkFromAuthorization(LIQUIDITY_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLiquidityManagerACL: recipient not allowed"));
    }


    function test_AddTokenWhitelist() public {
        MerlinSwapLiquidityManagerAuthorizationACLMock acl = new MerlinSwapLiquidityManagerAuthorizationACLMock(
            address(_guardian), safeAccount, LIQUIDITY_MANAGER, new address[](0)
        );
        acl.addTokenWhitelist(WBTC);
        assertTrue(acl.checkToken(WBTC));
        assertFalse(acl.checkToken(WETH));
    }

    function test_RevertWhenAddInvalidTokenWhitelist() public {
        MerlinSwapLiquidityManagerAuthorizationACLMock acl = new MerlinSwapLiquidityManagerAuthorizationACLMock(
            address(_guardian), safeAccount, LIQUIDITY_MANAGER, new address[](0)
        );
        vm.expectRevert("MerlinSwapLiquidityManagerACL: token cannot be the zero address");
        acl.addTokenWhitelist(address(0));
    }
}

contract MerlinSwapLiquidityManagerAuthorizationACLMock is MerlinSwapLiquidityManagerAuthorizationACL {
    constructor(
        address caller_,
        address safeAccount_,
        address merlinSwap_,
        address[] memory tokenWhitelist_
    ) 
        MerlinSwapLiquidityManagerAuthorizationACL(caller_, safeAccount_, merlinSwap_, tokenWhitelist_) {}

    function addTokenWhitelist(address token_) external {
        _addTokenWhitelist(token_);
    }

    function checkToken(address token_) external view returns (bool) {
        return _checkToken(token_);
    }
}
