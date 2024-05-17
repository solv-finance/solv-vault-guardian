// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/merlinswap/MerlinSwapLimitOrderManagerAuthorization.sol";
import "../../src/authorizations/merlinswap/MerlinSwapLimitOrderManagerAuthorizationACL.sol";

contract MerlinSwapLimitOrderManagerAuthorizationTest is AuthorizationTestBase {

    address internal constant LIMIT_ORDER_MANAGER = 0x72fAfc28bFf27BB7a5cf70585CA1A5185AD2f201;

    function setUp() public override {
        super.setUp();

        address[] memory tokenWhitelist = new address[](3);
        tokenWhitelist[0] = WETH;
        tokenWhitelist[1] = WBTC;
        tokenWhitelist[2] = USDT;
        _authorization = new MerlinSwapLimitOrderManagerAuthorization(address(_guardian), safeAccount, LIMIT_ORDER_MANAGER, tokenWhitelist);
    }

    function test_AuthorizationInitialStatus() public {
        address acl = _authorization.getACLByContract(LIMIT_ORDER_MANAGER);
        assertNotEq(acl, address(0));
    }

    function test_NewLimOrder() public {
        bytes memory txData = abi.encodeWithSignature(
            "newLimOrder(uint256,(address,address,uint24,int24,uint128,bool,uint256))", 
            1, ILimitOrderManager.AddLimOrderParam(WBTC, USDT, uint24(500), int24(800001), 1 ether, true, block.timestamp + 300)
        );
        _checkFromAuthorization(LIMIT_ORDER_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_CollectLimOrder() public {
        bytes memory txData = abi.encodeWithSignature(
            "collectLimOrder(address,uint256,uint128,uint128)", 
            safeAccount, 1, 1 ether, 1 ether
        );
        _checkFromAuthorization(LIMIT_ORDER_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_DecLimOrder() public {
        bytes memory txData = abi.encodeWithSignature(
            "decLimOrder(uint256,uint128,uint256)", 
            1, 1 ether, block.timestamp + 300
        );
        _checkFromAuthorization(LIMIT_ORDER_MANAGER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenNewLimOrderWithInvalidTokenX() public {
        bytes memory txData = abi.encodeWithSignature(
            "newLimOrder(uint256,(address,address,uint24,int24,uint128,bool,uint256))", 
            1, ILimitOrderManager.AddLimOrderParam(USDC, USDT, uint24(500), int24(800001), 1 ether, true, block.timestamp + 300)
        );
        _checkFromAuthorization(LIMIT_ORDER_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLimitOrderManagerACL: tokenX not allowed"));
    }

    function test_RevertWhenNewLimOrderWithInvalidTokenY() public {
        bytes memory txData = abi.encodeWithSignature(
            "newLimOrder(uint256,(address,address,uint24,int24,uint128,bool,uint256))", 
            1, ILimitOrderManager.AddLimOrderParam(WBTC, USDC, uint24(500), int24(800001), 1 ether, true, block.timestamp + 300)
        );
        _checkFromAuthorization(LIMIT_ORDER_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLimitOrderManagerACL: tokenY not allowed"));
    }

    function test_RevertWhenCollectLimOrderWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "collectLimOrder(address,uint256,uint128,uint128)", 
            permissionlessAccount, 1, 1 ether, 1 ether
        );
        _checkFromAuthorization(LIMIT_ORDER_MANAGER, 0, txData, Type.CheckResult(false, "MerlinSwapLimitOrderManagerACL: recipient not allowed"));
    }


    function test_AddTokenWhitelist() public {
        MerlinSwapLimitOrderManagerAuthorizationACLMock acl = new MerlinSwapLimitOrderManagerAuthorizationACLMock(
            address(_guardian), safeAccount, LIMIT_ORDER_MANAGER, new address[](0)
        );
        acl.addTokenWhitelist(WBTC);
        assertTrue(acl.checkToken(WBTC));
        assertFalse(acl.checkToken(WETH));
    }

    function test_RevertWhenAddInvalidTokenWhitelist() public {
        MerlinSwapLimitOrderManagerAuthorizationACLMock acl = new MerlinSwapLimitOrderManagerAuthorizationACLMock(
            address(_guardian), safeAccount, LIMIT_ORDER_MANAGER, new address[](0)
        );
        vm.expectRevert("MerlinSwapLimitOrderManagerACL: token cannot be the zero address");
        acl.addTokenWhitelist(address(0));
    }
}

contract MerlinSwapLimitOrderManagerAuthorizationACLMock is MerlinSwapLimitOrderManagerAuthorizationACL {
    constructor(
        address caller_,
        address safeAccount_,
        address merlinSwap_,
        address[] memory tokenWhitelist_
    ) 
        MerlinSwapLimitOrderManagerAuthorizationACL(caller_, safeAccount_, merlinSwap_, tokenWhitelist_) {}

    function addTokenWhitelist(address token_) external {
        _addTokenWhitelist(token_);
    }

    function checkToken(address token_) external view returns (bool) {
        return _checkToken(token_);
    }
}
