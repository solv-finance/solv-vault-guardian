// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/common/FunctionGuard.sol";
import "./SafeguardBaseTest.sol";

contract FunctionGuardMock is FunctionGuard {
	address public constant GLP_REWAED_ROUTER = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;

	constructor() {
		string[] memory glpRewardRouterFuncs = new string[](2);
		glpRewardRouterFuncs[0] = "mintAndStakeGlp(address,uint256,uint256,uint256)";
		glpRewardRouterFuncs[1] = "unstakeAndRedeemGlp(address,uint256,uint256,address)";
		_addContractFuncs(GLP_REWAED_ROUTER, glpRewardRouterFuncs);
	}
}

contract FunctionGuardTest is SafeguardBaseTest {
	FunctionGuardMock functionGuard;
	function setUp() public override {
		functionGuard = new FunctionGuardMock();
	}

	function testCheckTransaction() public {
		bytes memory data = hex"364e2311000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb900000000000000000000000000000000000000000000000000000000000b71b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b02213227cc2400";
		BaseGuard.TxData memory txData = BaseGuard.TxData({
			from: _msgSender,
			to: functionGuard.GLP_REWAED_ROUTER(),
			value: 0,
			data: data
		});
		assertTrue(functionGuard.checkTransaction(txData).success);
	}
}