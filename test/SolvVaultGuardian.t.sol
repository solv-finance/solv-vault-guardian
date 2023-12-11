// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./common/SolvVaultGuardianBaseTest.sol";
import "../src/authorizations/ERC20TransferAuthorization.sol";

contract SolvVaultGuardianTest is SolvVaultGuardianBaseTest {
    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardian(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor);
        super._setSafeGuard();
    }

    function testFail_TransferNativeToken() public {
        vm.startPrank(governor);
        super._nativeTokenTransfer(CEX_RECHARGE_ADDRESS, 0.001 ether);
        vm.stopPrank();
    }

    function testFail_TransferNativeTokenWithOutSetReceiver() public {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        super._nativeTokenTransfer(CEX_RECHARGE_ADDRESS, 0.001 ether);
        vm.stopPrank();
    }

    function testSuccess_TransferNativeToken() public {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receivers = new address[](1);
        receivers[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receivers);
        super._nativeTokenTransfer(CEX_RECHARGE_ADDRESS, 0.001 ether);
        vm.stopPrank();
    }
}
