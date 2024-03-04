// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/lendle/LendleAuthorization.sol";
import "../../src/authorizations/lendle/LendleAuthorizationACL.sol";

contract LendleAuthorizationTest is SolvVaultGuardianBaseTest {

    address internal constant LENDLE_POOL = 0xCFa5aE7c2CE8Fadc6426C1ff872cA45378Fb7cF3;

    LendleAuthorization internal _lendleAuthorization;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        address[] memory assetWhitelist = new address[](2);
        assetWhitelist[0] = WETH;
        assetWhitelist[1] = USDT;
        _lendleAuthorization = new LendleAuthorization(address(_guardian), safeAccount, LENDLE_POOL, assetWhitelist);
        _addLendleAuthorization();
    }

    function test_AuthorizationInitialStatus() public virtual {
        address acl = _lendleAuthorization.getACLByContract(LENDLE_POOL);
        assertNotEq(acl, address(0));
    }

    function test_GuardianInitialStatus() public virtual {
        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 1);
        assertEq(toAddresses[0], LENDLE_POOL);
    }

    function test_Deposit() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            WETH, 1 ether, safeAccount, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_Withdraw() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            USDT, 1 ether, safeAccount, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_Borrow() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            USDT, 1 ether, 0, 0, safeAccount
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_Repay() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            USDT, 1 ether, 0, safeAccount
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_SwapBorrowRateMode() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "swapBorrowRateMode(address,uint256)", 
            USDT, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDepositWithInvalidBehalf() public virtual {
        _revertMessage = "LendleACL: onBehalfOf not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            WETH, 1 ether, permissionlessAccount, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenDepositWithInvalidAsset() public virtual {
        _revertMessage = "LendleACL: asset not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "deposit(address,uint256,address,uint16)", 
            WBTC, 1 ether, safeAccount, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdrawWithInvalidBehalf() public virtual {
        _revertMessage = "LendleACL: recipient not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            USDT, 1 ether, permissionlessAccount, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenBorrowWithInvalidAsset() public virtual {
        _revertMessage = "LendleACL: asset not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "withdraw(address,uint256,address)", 
            USDC, 1 ether, safeAccount, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenBorrowWithInvalidBehalf() public virtual {
        _revertMessage = "LendleACL: onBehalfOf not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            USDT, 1 ether, 0, 0, permissionlessAccount
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenWithdrawWithInvalidAsset() public virtual {
        _revertMessage = "LendleACL: asset not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint16,address)", 
            USDC, 1 ether, 0, 0, safeAccount
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenRepayWithInvalidBehalf() public virtual {
        _revertMessage = "LendleACL: onBehalfOf not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            USDT, 1 ether, 0, permissionlessAccount
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenRepayWithInvalidAsset() public virtual {
        _revertMessage = "LendleACL: asset not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "repay(address,uint256,uint256,address)", 
            USDC, 1 ether, 0, safeAccount
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenSwapBorrowRateModeWithInvalidAsset() public virtual {
        _revertMessage = "LendleACL: asset not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "swapBorrowRateMode(address,uint256)", 
            USDC, 0
        );
        _checkFromGuardian(LENDLE_POOL, 0, txData, Enum.Operation.Call);
    }

    function _addLendleAuthorization() internal virtual {
        vm.startPrank(governor);
        _guardian.setAuthorization(LENDLE_POOL, address(_lendleAuthorization));
        vm.stopPrank();
    }

}
