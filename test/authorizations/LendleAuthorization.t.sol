// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/lendle/LendleAuthorization.sol";
import "../../src/authorizations/lendle/LendleAuthorizationACL.sol";

contract LendleAuthorizationTest is AuthorizationTestBase {

    address internal constant LENDLE_POOL = 0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3;

    LendleAuthorization internal _lendleAuthorization;

    function setUp() public virtual override {
        super.setUp();
        
        address[] memory assetWhitelist = new address[](2);
        assetWhitelist[0] = WETH;
        assetWhitelist[1] = USDT;
        _lendleAuthorization = new LendleAuthorization(address(_guardian), safeAccount, LENDLE_POOL, assetWhitelist);
        _authorization = _lendleAuthorization;
    }

    function test_AuthorizationInitialStatus() public virtual {
        address acl = _lendleAuthorization.getACLByContract(LENDLE_POOL);
        assertNotEq(acl, address(0));
    }

    function test_Deposit() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            WETH, 1 ether, safeAccount, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Withdraw() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            USDT, 1 ether, safeAccount, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Borrow() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            USDT, 1 ether, 0, 0, safeAccount
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Repay() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            USDT, 1 ether, 0, safeAccount
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SwapBorrowRateMode() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "swapBorrowRateMode(address,uint256)", 
            USDT, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenDepositWithInvalidBehalf() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            WETH, 1 ether, permissionlessAccount, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: onBehalfOf not allowed"));
    }

    function test_RevertWhenDepositWithInvalidAsset() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            WBTC, 1 ether, safeAccount, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: asset not allowed"));
    }

    function test_RevertWhenWithdrawWithInvalidBehalf() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            USDT, 1 ether, permissionlessAccount, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: recipient not allowed"));
    }

    function test_RevertWhenBorrowWithInvalidAsset() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            USDC, 1 ether, safeAccount, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: asset not allowed"));
    }

    function test_RevertWhenBorrowWithInvalidBehalf() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            USDT, 1 ether, 0, 0, permissionlessAccount
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: onBehalfOf not allowed"));
    }

    function test_RevertWhenWithdrawWithInvalidAsset() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            USDC, 1 ether, 0, 0, safeAccount
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: asset not allowed"));
    }

    function test_RevertWhenRepayWithInvalidBehalf() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            USDT, 1 ether, 0, permissionlessAccount
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: onBehalfOf not allowed"));
    }

    function test_RevertWhenRepayWithInvalidAsset() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            USDC, 1 ether, 0, safeAccount
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: asset not allowed"));
    }

    function test_RevertWhenSwapBorrowRateModeWithInvalidAsset() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "swapBorrowRateMode(address,uint256)", 
            USDC, 0
        );
        _checkFromAuthorization(LENDLE_POOL, 0, txData, Type.CheckResult(false, "LendleACL: asset not allowed"));
    }

    function test_AddTokenWhitelist() public virtual {
        LendleAuthorizationACLMock acl = new LendleAuthorizationACLMock(
            address(_guardian), safeAccount, LENDLE_POOL, new address[](0)
        );
        acl.addTokenWhitelist(WBTC);
        assertTrue(acl.checkToken(WBTC));
        assertFalse(acl.checkToken(WETH));
    }

    function test_RevertWhenAddInvalidTokenWhitelist() public virtual {
        LendleAuthorizationACLMock acl = new LendleAuthorizationACLMock(
            address(_guardian), safeAccount, LENDLE_POOL, new address[](0)
        );
        vm.expectRevert("LendleACL: token cannot be the zero address");
        acl.addTokenWhitelist(address(0));
    }

}

contract LendleAuthorizationACLMock is LendleAuthorizationACL {
    constructor(
        address caller_,
        address safeAccount_,
        address lendingPool_,
        address[] memory tokenWhitelist_
    )
        LendleAuthorizationACL(caller_, safeAccount_, lendingPool_, tokenWhitelist_) {}
    
    function addTokenWhitelist(address token_) external virtual {
        _addTokenWhitelist(token_);
    }

    function checkToken(address token_) external view virtual returns (bool) {
        return _checkToken(token_);
    }
}