// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./common/SafeguardBaseTest.sol";
import "../src/GMXV2SolvSafeguard.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract GMXV1SolvSafeguardTest is SafeguardBaseTest {

	address public constant ARGUS_GMXV2_ACL = 0x3d0f0084E6D8C28f9E0044027E80c774fbC110f1;

	GMXV2SolvSafeguard internal _gmxV2SolvSafeguard;

	function setUp() public virtual override {
		super.setUp();
		_gmxV2SolvSafeguard = _createGMXV2SolvSafeguard();
	}

	function _createGMXV2SolvSafeguard() internal returns (GMXV2SolvSafeguard safeguard_) {
		safeguard_ = new GMXV2SolvSafeguard(
			SAFE_ACCOUNT,
			SAFE_ACCOUNT,
			USDT,
			CEX_RECHARGE_ADDRESS,
			OPEN_END_FUND_MARKET,
			OPEN_END_FUND_SHARE,
			OPEN_END_FUND_REDEMPTION
		);
		_setSafeGuard(address(safeguard_));
	}

	// function test_WithGuard_GMXV1_E2E_SUCCESS() public {
	// 	_initArgus();
	// 	_rechargeCEX();
	// 	_buyAndStakeGLP();
	// 	_unstakeAndSellGlp();
	// }

	function test_argus_operations_success() public {
		//initArgus
		bytes memory data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000990158d3a5586a8083a207a01f21b9711579217448070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004446998353000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c01c106fadebbb2d32c2eacab3f5874b25b009cbb32000000000000000000000000000000000000";
		_callExecTransaction(SAFE_MULTI_SEND_CONTRACT, 0, data, Enum.Operation.DelegateCall);

		//addRoles
		data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000b90080346efdc8957843a472e5fdad12ea4fd340a845000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000645e7c67db000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000014f70657261746f7200000000000000000000000000000000000000000000000000000000000000";
		_callExecTransaction(SAFE_MULTI_SEND_CONTRACT, 0, data, Enum.Operation.DelegateCall);

		//GrantRoles
		data = hex"8d80ff0a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001390158d3a5586a8083a207a01f21b971157921744807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e47fa71fb400000000000000000000000022809600e06572d424f8aa65b56a0280f7e2765f000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001676d782d7631000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004b2e4cac67786778c79beccc8c800e325ab3bdda00000000000000";
		_callExecTransaction(SAFE_MULTI_SEND_CONTRACT, 0, data, Enum.Operation.DelegateCall);

		//AddGmxAuthorizer
		// data = hex"8d80ff0a00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000c850158d3a5586a8083a207a01f21b971157921744807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000841f76a7cc000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c00000000000000000000000022809600e06572d424f8aa65b56a0280f7e2765f476d78476c70417574686f72697a6572000000000000000000000000000000004172677573474d5856312d474d585f4c5000000000000000000000000000000000fd11981da6af3142555e3c8b60d868c7d7ee1963000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001847a796db40000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000af88d065e77c8cc2239327c5edb3a432268e5831000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da1000000000000000000000000fa7f8980b0f1e64a2062791cc3b0871572f1f7f000000000000000000000000017fc002b466eec40dae837fc4be5c67993ddbd6f0000000000000000000000002f2a2543b76a4166549f7aab2e75bef0aefc5b0f000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc800000000000000000000000082af49447d8a07e3bd95bd0d56f35241523fbab1000000000000000000000000f97f4df75117a78c1a5a0dbb814af92458539fb40158d3a5586a8083a207a01f21b971157921744807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c48cb9743500000000000000000000000022809600e06572d424f8aa65b56a0280f7e2765f000000000000000000000000fd11981da6af3142555e3c8b60d868c7d7ee1963000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001676d782d763100000000000000000000000000000000000000000000000000000158d3a5586a8083a207a01f21b971157921744807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003049ed2c861000000000000000000000000c0b00000e19d71fa50a9bb1fcac2ec92fac9549c00000000000000000000000022809600e06572d424f8aa65b56a0280f7e2765f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001604172677573474d5856312d436c61696d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001676d782d763100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000a906f338cb21815cbc4bc87ace9e68c87ef8d8f1000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000007636c61696d282900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a636f6d706f756e64282900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003168616e646c655265776172647328626f6f6c2c626f6f6c2c626f6f6c2c626f6f6c2c626f6f6c2c626f6f6c2c626f6f6c290000000000000000000000000000000082af49447d8a07e3bd95bd0d56f35241523fbab100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff002f2a2543b76a4166549f7aab2e75bef0aefc5b0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00f97f4df75117a78c1a5a0dbb814af92458539fb400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00fa7f8980b0f1e64a2062791cc3b0871572f1f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ff970a61a04b1ca14834a43f5de4533ebddb5cc800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00af88d065e77c8cc2239327c5edb3a432268e583100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00da10009cbd5d07dd0cecc66161fc93d7c9000da100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0017fc002b466eec40dae837fc4be5c67993ddbd6f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000003963ffc9dff443c2a94f21b129d429891e32ec18ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000";
		// _callExecTransaction(SAFE_MULTI_SEND_CONTRACT, 0, data, Enum.Operation.DelegateCall);
	}
}