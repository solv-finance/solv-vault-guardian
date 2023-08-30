// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./SafeguardBaseTest.sol";


contract SolvSafeguardTest is SafeguardBaseTest {
	address payable public constant safeAddress = payable(0x01c106FadEbBB2D32c2EAcAB3F5874B25B009cbb);
	address public constant safeERC20Address = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; //USDT
	address public constant allowedTransferTo = 0xF6BeF585274b100764ed9a2A54EF3B14384725b7;
	address public constant banTransferTo = 0x8E162227fbc6D8566449Dcf06dEbB622B057F784;


	function test_CheckTransaction_CEXRecharge() public {
		revert("NOT Implemented");
	}

	function test_CheckTransaction_CoboArgusConfigure() public {
		revert("NOT Implemented");
	}

	function test_CheckTransaction_OpenFundSettlement() public {
		revert("NOT Implemented");
	}

	function test_checkTransaction_OpenFundRedempt() public {
		revert("NOT Implemented");
	}

}