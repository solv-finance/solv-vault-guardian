// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./common/SafeguardBaseTest.sol";
import {GMXV1SolvSafeguardTest} from "./GMXV1SolvSafeguard.t.sol";

contract GMXV1SolvSafeguardV1Test is GMXV1SolvSafeguardTest {
	function setUp() public override {
		super.setUp();
		// _gmxV1SolvSafeguard.setSolvGuards(new address[](0));
	}

	function test_Empty_Guards() public {
		// assertTrue(_gmxV1SolvSafeguard.getSolvGuards().length == 0);
	}

	function test_WithoutGuards_GMXV1_E2E_SUCCESS() public {
		_initArgus();
		_rechargeCEX();
		_buyAndStakeGLP();
		_unstakeAndSellGlp();
	}
}