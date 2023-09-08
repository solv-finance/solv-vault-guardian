// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./SafeguardBaseTest.sol";
import "../src/guards/CEXRechargeGuard.sol";

contract CEXRechargeGuardTest is SafeguardBaseTest {
	address public constant cexRechargeERC20 = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT
	address public constant cexNOTRechargeERC20 = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000; //DEAD
	address public constant cexRechargeAddress = 0xF6BeF585274b100764ed9a2A54EF3B14384725b7;
	address public constant banTransferTo = 0x8E162227fbc6D8566449Dcf06dEbB622B057F784;
	CEXRechargeGuard internal _cexRechargeGuard;

	function setUp() public override {
		super.setUp();
		_createCEXRerchargeGuard(cexRechargeERC20, cexRechargeAddress);
	}

	function _createCEXRerchargeGuard(address token_, address to_) internal{
		CEXRechargeGuard.TokenReceiver[] memory receivers = new CEXRechargeGuard.TokenReceiver[](1);
		receivers[0] = TransferGuard.TokenReceiver({
			token: token_,
			receiver: to_
		});

		_cexRechargeGuard = new CEXRechargeGuard(receivers);
	}

	function test_CEXRecharge_success() public {
		_checkTransfer(cexRechargeERC20, cexRechargeAddress, true);
	}

	function test_CEXRecharge_fail_with_notallow_Address() public {
		_checkTransfer(cexRechargeERC20, banTransferTo, false);
	}

	function test_CEXRecharge_vert_with_notallow_token() public {
		_checkTransfer(cexNOTRechargeERC20, cexRechargeAddress, false);
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
		BaseGuard.CheckResult memory result =  _cexRechargeGuard.checkTransaction(txData);
		assertEq(result.success, expected_, result.message);
		vm.stopPrank();
	}
}