// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./common/SolvVaultGuardianBaseTest.sol";
import "../src/authorizations/ERC20TransferAuthorization.sol";

contract SolvVaultGuardianTest is SolvVaultGuardianBaseTest {
    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();
    }

    /**
     * Tests for native token transfer
     */

    function test_TransferNativeToken() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0.001 ether);
    }

    function test_TransferNativeTokenToSelf() public virtual {
        super._nativeTokenTransferWithSafe(safeAccount, 0.001 ether);
    }

    function test_RevertWhenTransferNativeTokenInInitialState() public virtual {
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0.001 ether);

        // when transfer value is zero
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0);
    }

    function test_TransferNativeTokenWhenReceiverIsNotInWhitelist() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();

        // allow native token transfer but receiver whitelist is empty
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0.001 ether);

        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = governor;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        // allow native token transfer but receiver not in whitelist
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0.001 ether);
    }

    function test_RevertWhenTransferNativeTokenWhenDisabled() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        _guardian.setNativeTokenTransferAllowed(false);
        vm.stopPrank();

        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 0.001 ether);
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

    /**
     * Test for setGuard function
     */
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

    function test_SetGuardWhenReenabled() public virtual {
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, false);
        _setSafeGuard();

        _revertMessage = "";
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

    function test_OpenEndFundCEXArbitrage() public virtual {}
}
