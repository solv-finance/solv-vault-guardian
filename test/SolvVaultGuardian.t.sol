// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./common/SolvVaultGuardianBaseTest.sol";

contract SolvVaultGuardianTest is SolvVaultGuardianBaseTest {

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();
    }

    function test_GuardianInitialStatus() public virtual {
        assertEq(_guardian.safeAccount(), safeAccount);
        assertTrue(_guardian.allowSetGuard());
        assertFalse(_guardian.allowNativeTokenTransfer());
    }

    /** Test for setGuard function */
    function test_SetGuard() public virtual {
        vm.startPrank(governor);
        _guardian.setGuardAllowed(true);
        vm.stopPrank();

        // change to another guard
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        _setSafeGuard();

        // reset guard
        _guardian = SolvVaultGuardianForSafe13(address(0));
        _setSafeGuard();
    }

    function test_AllowSetGuardStatus() public virtual {
        vm.startPrank(governor);
        _guardian.setGuardAllowed(true);
        assertTrue(_guardian.allowSetGuard());
        _guardian.setGuardAllowed(false);
        assertFalse(_guardian.allowSetGuard());
        vm.stopPrank();
    }

    function test_SetGuardWhenReenabled() public virtual {
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, false);
        _setSafeGuard();

        vm.startPrank(governor);
        _guardian.setGuardAllowed(true);
        vm.stopPrank();

        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        _setSafeGuard();
    }

    function test_RevertWhenSetGuardIsNotAllowedInInitialState() public virtual {
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, false);
        _setSafeGuard();

        // change to another guard
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, false);
        _revertMessage = "SolvVaultGuardian: setGuard disabled";
        _setSafeGuard();

        // reset guard
        _guardian = SolvVaultGuardianForSafe13(address(0));
        _revertMessage = "SolvVaultGuardian: setGuard disabled";
        _setSafeGuard();
    }

    function test_RevertWhenSetGuardWhenDisabled() public virtual {
        vm.startPrank(governor);
        _guardian.setGuardAllowed(false);
        vm.stopPrank();

        // change to another guard
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, false);
        _revertMessage = "SolvVaultGuardian: setGuard disabled";
        _setSafeGuard();

        // reset guard
        _guardian = SolvVaultGuardianForSafe13(address(0));
        _revertMessage = "SolvVaultGuardian: setGuard disabled";
        super._setSafeGuard();
    }

    function test_RevertWhenAllowSetGuardByNonGovernor() public virtual {
        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _guardian.setGuardAllowed(false);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only governor");
        _guardian.setGuardAllowed(true);
        vm.stopPrank();
    }

    /** Tests for native token transfer */
    function test_TransferNativeToken1() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 1 ether);
    }

    function test_NativeTokenTransferStatus() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        assertTrue(_guardian.allowNativeTokenTransfer());
        assertTrue(_guardian.nativeTokenReceiver(CEX_RECHARGE_ADDRESS));

        _guardian.removeNativeTokenReceiver(receiverWhitelist);
        assertFalse(_guardian.nativeTokenReceiver(CEX_RECHARGE_ADDRESS));

        _guardian.setNativeTokenTransferAllowed(false);
        assertFalse(_guardian.allowNativeTokenTransfer());
        vm.stopPrank();
    }

    function test_TransferNativeTokenToSelf() public virtual {
        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafe(safeAccount, 1 ether);
    }

    function test_RevertWhenTransferNativeTokenInInitialState() public virtual {
        hoax(safeAccount, 10 ether);
        _revertMessage = "SolvVaultGuardian: native token transfer not allowed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 1 ether);

        // when transfer value is zero
        _revertMessage = "SolvVaultGuardian: native token transfer not allowed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0);
    }

    function test_RevertWhenReceiverIsNotInWhitelist() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();

        hoax(safeAccount, 10 ether);
        _revertMessage = "SolvVaultGuardian: native token receiver not allowed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 1 ether);

        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = governor;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        _revertMessage = "SolvVaultGuardian: native token receiver not allowed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 1 ether);
    }

    function test_RevertWhenTransferNativeTokenIsDisabled() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        _guardian.setNativeTokenTransferAllowed(false);
        vm.stopPrank();

        hoax(safeAccount, 10 ether);
        _revertMessage = "SolvVaultGuardian: native token transfer not allowed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 1 ether);
    }

    function test_RevertWhenAllowTransferNativeTokenByNonGovernor() public virtual {
        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only governor");
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();
    }

    function test_RevertWhenAddNativeTokenReceiversByNonGovernor() public virtual {
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;

        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only governor");
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();
    }

}
