// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../common/SafeguardBaseTest.sol";
import "../../../src/strategies/guards/CoboArgusAdminGuard.sol";

//fork aribtrum block number 128520500
contract CoboArgusAdminGuardTest is SafeguardBaseTest {
	CoboArgusAdminGuard internal _coboArgusGuard;

	function setUp() public override {
		super.setUp();
		_createCoboArgusGuard();
	}

	function _createCoboArgusGuard() internal{
		_coboArgusGuard = new CoboArgusAdminGuard();
	}

	function test_MulitSend_InitArgus_SUCCESS() public {
		bytes memory data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000990158d3a5586a8083a207a01f21b9711579217448070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004446998353000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c01c106fadebbb2d32c2eacab3f5874b25b009cbb32000000000000000000000000000000000000";
		BaseGuard.TxData memory txData = BaseGuard.TxData({
			from: _msgSender,
			to: _coboArgusGuard.SAFE_MULTI_SEND_CONTRACT(),
			value: 0,
			data: data
		});
		BaseGuard.CheckResult memory result = _coboArgusGuard.checkTransaction(txData);
		assertTrue(result.success);
	}

	// function test_MulitSend_AddRoles_SUCCESS() public {
	// 	bytes memory data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000b90080346efdc8957843a472e5fdad12ea4fd340a845000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000645e7c67db000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000014f70657261746f7200000000000000000000000000000000000000000000000000000000000000";
	// 	BaseGuard.TxData memory txData = BaseGuard.TxData({
	// 		from: _msgSender,
	// 		to: _coboArgusGuard.SAFE_MULTI_SEND_CONTRACT(),
	// 		value: 0,
	// 		data: data
	// 	});
	// 	BaseGuard.CheckResult memory result = _coboArgusGuard.checkTransaction(txData);
	// 	assertTrue(result.success);
	// }

	// function test_MulitSend_GrantRoles_SUCCESS() public {
	// 	bytes memory data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001390158d3a5586a8083a207a01f21b971157921744807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e47fa71fb400000000000000000000000022809600e06572d424f8aa65b56a0280f7e2765f000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001676d782d7631000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004b2e4cac67786778c79beccc8c800e325ab3bdda00000000000000";
	// 	BaseGuard.TxData memory txData = BaseGuard.TxData({
	// 		from: _msgSender,
	// 		to: _coboArgusGuard.SAFE_MULTI_SEND_CONTRACT(),
	// 		value: 0,
	// 		data: data
	// 	});
	// 	BaseGuard.CheckResult memory result = _coboArgusGuard.checkTransaction(txData);
	// 	assertTrue(result.success);
	// }

	// function test_MulitSend_InitArgus_ErrorContract_FAIL() public {
	// 	bytes memory data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000990158d3a5586a8083a207a01f21b9711579217448060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004446998353000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c01c106fadebbb2d32c2eacab3f5874b25b009cbb32000000000000000000000000000000000000";
	// 	BaseGuard.TxData memory txData = BaseGuard.TxData({
	// 		from: _msgSender,
	// 		to: _coboArgusGuard.SAFE_MULTI_SEND_CONTRACT(),
	// 		value: 0,
	// 		data: data
	// 	});
	// 	BaseGuard.CheckResult memory result = _coboArgusGuard.checkTransaction(txData);
	// 	assertFalse(result.success);
	// }

	// function test_MultiSend_OtherFunction_FAIL() public {
	// 	bytes memory data = hex"8f80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000990158d3a5586a8083a207a01f21b9711579217448060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004446998353000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c01c106fadebbb2d32c2eacab3f5874b25b009cbb32000000000000000000000000000000000000";
	// 	BaseGuard.TxData memory txData = BaseGuard.TxData({
	// 		from: _msgSender,
	// 		to: _coboArgusGuard.SAFE_MULTI_SEND_CONTRACT(),
	// 		value: 0,
	// 		data: data
	// 	});
	// 	BaseGuard.CheckResult memory result = _coboArgusGuard.checkTransaction(txData);
	// 	assertFalse(result.success);
	// }

	// function test_MulitSend_InitArgus_OtherFunction_FAIL() public {
	// 	bytes memory data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000990158d3a5586a8083a207a01f21b971157921744806000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444a998353000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c01c106fadebbb2d32c2eacab3f5874b25b009cbb32000000000000000000000000000000000000";
	// 	BaseGuard.TxData memory txData = BaseGuard.TxData({
	// 		from: _msgSender,
	// 		to: _coboArgusGuard.SAFE_MULTI_SEND_CONTRACT(),
	// 		value: 0,
	// 		data: data
	// 	});
	// 	BaseGuard.CheckResult memory result = _coboArgusGuard.checkTransaction(txData);
	// 	assertFalse(result.success);
	// }

}