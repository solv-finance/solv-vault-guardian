// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeguardBaseTest.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract GuardManagerGuardTest is SafeguardBaseTest {

	GuardManagerGuard internal _guardManagerGuard;

	function setUp() public override {
		super.setUp();
		_createGuardManagerGuard(SAFE_ACCOUNT, SAFE_GOVERNOR);
	}

	function _createGuardManagerGuard(address safeAccount_, address safeGovernor_) internal {
		_guardManagerGuard = new GuardManagerGuard(safeAccount_, safeGovernor_);
	}

	function test_SetGuard_by_default_SUCCESS() public {
		bytes memory data = hex"e19a9dd900000000000000000000000015f043cfc880b3e17ffd15e6d0a4dc17a951a863";
		BaseGuard.TxData memory txData = BaseGuard.TxData({
			from: address(SAFE_ACCOUNT),
			to: SAFE_ACCOUNT,
			value: 0,
			data: data
		});
		BaseGuard.CheckResult memory result = _guardManagerGuard.checkTransaction(txData);
		assertTrue(result.success);
	}

	function test_SetGuard_after_forbidden_FAIL() public {
		_forbidSetGuard();
		assertFalse(_guardManagerGuard.allowSetGuard());
		bytes memory data = hex"e19a9dd900000000000000000000000015f043cfc880b3e17ffd15e6d0a4dc17a951a863";
		BaseGuard.TxData memory txData = BaseGuard.TxData({
			from: address(SAFE_GOVERNOR),
			to: SAFE_ACCOUNT,
			value: 0,
			data: data
		});
		BaseGuard.CheckResult memory result = _guardManagerGuard.checkTransaction(txData);
		assertFalse(result.success);
		assertEq(result.message, "GuardManagerGuard: set guard not allowed");
	}

	function _forbidSetGuard() internal virtual {
		vm.startPrank(address(SAFE_GOVERNOR));
		_guardManagerGuard.forbidSetGuard();
        vm.stopPrank();
	}
}