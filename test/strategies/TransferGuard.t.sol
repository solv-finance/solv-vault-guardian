// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../common/SafeguardBaseTest.sol";
import "../../src/strategies/TransferGuard.sol";

contract TransferGuardTest is SafeguardBaseTest {
	address public constant TransferERC20 = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT
	address public constant cexNOTRechargeERC20 = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000; //DEAD
	address public constant TransferAddress = 0xF6BeF585274b100764ed9a2A54EF3B14384725b7;
	address public constant banTransferTo = 0x8E162227fbc6D8566449Dcf06dEbB622B057F784;
	TransferGuard internal _transferGuard;

	function setUp() public override {
		super.setUp();
		_createCEXRerchargeGuard(TransferERC20, TransferAddress);
	}

	function _createCEXRerchargeGuard(address token_, address to_) internal{
		TransferGuard.TokenReceiver[] memory receivers = new TransferGuard.TokenReceiver[](1);
		receivers[0] = TransferGuard.TokenReceiver({
			token: token_,
			receiver: to_
		});

		_transferGuard = new TransferGuard(receivers);
	}

	function test_Transfer_SUCCESS() public {
		_checkTransfer(TransferERC20, TransferAddress, true);
	}

	function test_Transfer_WithNotAllowAddress_FAIL() public {
		_checkTransfer(TransferERC20, banTransferTo, false);
	}

	function test_Transfer_WithNotAllowToken_FAIL() public {
		_checkTransfer(cexNOTRechargeERC20, TransferAddress, false);
	}

	function _checkTransfer(address token_, address to_, bool expected_) internal {
		bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to_, 1000);
		BaseGuard.TxData memory txData = BaseGuard.TxData({
			from: _msgSender,
			to: token_,
			value: 0,
			data: data
		});
		vm.startPrank(_msgSender);
		BaseGuard.CheckResult memory result =  _transferGuard.checkTransaction(txData);
		assertEq(result.success, expected_, result.message);
		vm.stopPrank();
	}
}