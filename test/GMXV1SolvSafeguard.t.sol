// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./common/GMXV1BaseTest.sol";
import {GMXV1SolvSafeguard} from "../src/GMXV1SolvSafeguard.sol";
import {GMXV1OpenEndFundGuard} from "../src/strategies/GMXV1OpenEndFundGuard.sol";

interface ERC20 {
	function balanceOf(address account) external view returns (uint256);
}

contract GMXV1SolvSafeguardTest is GMXV1BaseTest {
	address public constant ARGUS_GMXV1_ACL = 0xFd11981Da6af3142555e3c8B60d868C7D7eE1963;

	function test_WithGuard_GMXV1_E2E_SUCCESS() public {
		_initArgus();
		_rechargeCEX();
		_buyAndStakeGLP();
		_unstakeAndSellGlp();
	}
}