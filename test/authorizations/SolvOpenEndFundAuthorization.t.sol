// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/solv-open-end-fund/SolvOpenEndFundAuthorization.sol";
import "../../src/authorizations/solv-open-end-fund/SolvOpenEndFundAuthorizationACL.sol";

contract SolvOpenEndFundAuthorizationTest is AuthorizationTestBase {

    bytes32 internal constant REPAYABLE_POOL_ID = 0xe037ef7b5f74bf3c988d8ae8ab06ad34643749ba9d217092297241420d600fce;
    uint256 internal constant REPAYABLE_SHARE_SLOT = 5310353805259224968786693768403624884928279211848504288200646724372830798580;
    uint256 internal constant REPAYABLE_REDEMPTION_SLOT = 101416907514717499784233976442019233034164294772973197460606941990026142027726;

    bytes32 internal constant UNREPAYABLE_POOL_ID = 0x0ef01fb59f931e3a3629255b04ce29f6cd428f674944789288a1264a79c7c931;
    uint256 internal constant UNREPAYABLE_SHARE_SLOT = 17873186957027148109033339637575361280044016486300679380351688892728620516739;
    uint256 internal constant UNREPAYABLE_REDEMPTION_SLOT = 6756642026404814179393135527655482004793591833073186990035744963805248473393;

    address internal constant OPEN_END_FUND_SHARE_CONCRETE = 0x9d9AaF63d073b4C0547285e98d126770a80C4dcE;
    address internal constant OPEN_END_FUND_REDEMPTION_CONCRETE = 0x5Fc1Dd6ce1744B8a45f815Fe808E936f5dc97320;

    SolvOpenEndFundAuthorization internal _openEndFundAuthorization;

    function setUp() public virtual override {
        super.setUp();

        bytes32[] memory repayablePoolIds = new bytes32[](1);
        repayablePoolIds[0] = REPAYABLE_POOL_ID;
        _openEndFundAuthorization = new SolvOpenEndFundAuthorization(
            address(_guardian), OPEN_END_FUND_SHARE, OPEN_END_FUND_REDEMPTION, repayablePoolIds
        );
        _authorization = _openEndFundAuthorization;
    }

    function test_AuthorizationInitialStatus() public virtual {
        address shareACL = _openEndFundAuthorization.getACLByContract(OPEN_END_FUND_SHARE);
        bytes32[] memory shareAllowedPoolIds = SolvOpenEndFundAuthorizationACL(shareACL).getAllRepayablePoolIds();
        assertEq(shareAllowedPoolIds.length, 1);
        assertEq(shareAllowedPoolIds[0], REPAYABLE_POOL_ID);

        address redemptionACL = _openEndFundAuthorization.getACLByContract(OPEN_END_FUND_REDEMPTION);
        bytes32[] memory redemptionAllowedPoolIds = SolvOpenEndFundAuthorizationACL(redemptionACL).getAllRepayablePoolIds();
        assertEq(redemptionAllowedPoolIds.length, 1);
        assertEq(redemptionAllowedPoolIds[0], REPAYABLE_POOL_ID);
    }

    function test_RepayETHToShare() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(ETH);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, ETH, 1025 ether);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 1025 ether, txData, Type.CheckResult(true, ""));
    }

    function test_RepayERC20ToShare() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RepayToShareWhenCurrencyBalanceIsNotZero() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotCurrencyBalance(uint256)", REPAYABLE_SHARE_SLOT),
            abi.encode(500)
        );
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 525e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RepayToShareWhenInterestRateIsNegative() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotExtInfo(uint256)", REPAYABLE_SHARE_SLOT), 
            abi.encode(governor, 100 ether, 1, -1000, true, "URI")
        );
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 975e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RepayETHToRedemption() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(ETH, 1.025 ether);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, ETH, 1025 ether);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 1025 ether, txData, Type.CheckResult(true, ""));
    }

    function test_RepayERC20ToRedemption() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 1.025e6);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RepayToRedemptionWhenCurrencyBalanceIsNotZero() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 1.025e6);
        vm.mockCall(
            OPEN_END_FUND_REDEMPTION_CONCRETE, abi.encodeWithSignature("slotCurrencyBalance(uint256)", REPAYABLE_REDEMPTION_SLOT),
            abi.encode(500)
        );
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 525e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RepayToRedemptionWhenInterestRateIsNegative() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 0.975e6);
        vm.mockCall(
            OPEN_END_FUND_REDEMPTION_CONCRETE, abi.encodeWithSignature("getRedeemInfo(uint256)", REPAYABLE_REDEMPTION_SLOT), 
            abi.encode(REPAYABLE_POOL_ID, USDT, 1704067200, 0.975e6)
        );
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 975e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenRepayToInvalidContractType() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        vm.mockCall(OPEN_END_FUND_SHARE, abi.encodeWithSignature("contractType()"), abi.encode("Other SFT"));
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 1025 ether);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: invalid contract type"));
    }

    function test_RevertWhenRepayETHToShareWithInvalidValue() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(ETH);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, ETH, 1025 ether);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 1026 ether, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: transaction value not matches"));
    }

    function test_RevertWhenRepayERC20ToShareWithETHValue() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 1025 ether, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: transaction value not allowed"));
    }

    function test_RevertWhenOverRepayToShare() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 1026e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: share over paid"));
    }

    function test_RevertWhenRepayToShareWithInvalidPoolId() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", UNREPAYABLE_SHARE_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: pool not repayable"));
    }

    function test_RevertWhenRepayToShareWhereInterestRateNotSet() public virtual {
        _createCommonMockCalls();
        _createDefaultShareMockCalls(USDT);
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotExtInfo(uint256)", REPAYABLE_SHARE_SLOT), 
            abi.encode(governor, 100 ether, 1, 0, false, "URI")
        );
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_SHARE_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_SHARE, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: interest rate not set"));
    }

    function test_RevertWhenRepayETHToRedemptionWithInvalidValue() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(ETH, 1.025 ether);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, ETH, 1025 ether);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 1026 ether, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: transaction value not matches"));
    }

    function test_RevertWhenRepayERC20ToRedemptionWithETHValue() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 1.025e6);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 1025 ether, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: transaction value not allowed"));
    }

    function test_RevertWhenOverRepayToRedemption() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 1.025e6);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 1026e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: redemption over paid"));
    }

    function test_RevertWhenRepayToRedemptionWithInvalidPoolId() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 1.025e6);
        vm.mockCall(
            OPEN_END_FUND_REDEMPTION_CONCRETE, abi.encodeWithSignature("getRedeemInfo(uint256)", REPAYABLE_REDEMPTION_SLOT), 
            abi.encode(UNREPAYABLE_POOL_ID, USDT, 1704067200, 1.025e6)
        );
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: pool not repayable"));
    }

    function test_RevertWhenRepayToRedemptionWhereInterestRateNotSet() public virtual {
        _createCommonMockCalls();
        _createDefaultRedemptionMockCalls(USDT, 0);
        bytes memory txData = abi.encodeWithSignature("repay(uint256,address,uint256)", REPAYABLE_REDEMPTION_SLOT, USDT, 1025e6);
        _checkFromAuthorization(OPEN_END_FUND_REDEMPTION, 0, txData, Type.CheckResult(false, "SolvOpenEndFundAuthorizationACL: redeem nav not set"));
    }


    /** Internal Functions */

    function _createCommonMockCalls() internal {
        vm.mockCall(OPEN_END_FUND_SHARE, abi.encodeWithSignature("contractType()"), abi.encode("Open Fund Shares"));
        vm.mockCall(OPEN_END_FUND_REDEMPTION, abi.encodeWithSignature("contractType()"), abi.encode("Open Fund Redemptions"));

        vm.mockCall(OPEN_END_FUND_SHARE, abi.encodeWithSignature("valueDecimals()"), abi.encode(18));
        vm.mockCall(OPEN_END_FUND_REDEMPTION, abi.encodeWithSignature("valueDecimals()"), abi.encode(18));

        vm.mockCall(USDT, abi.encodeWithSignature("decimals()"), abi.encode(6));

        vm.mockCall(OPEN_END_FUND_SHARE, abi.encodeWithSignature("concrete()"), abi.encode(OPEN_END_FUND_SHARE_CONCRETE));
        vm.mockCall(OPEN_END_FUND_REDEMPTION, abi.encodeWithSignature("concrete()"), abi.encode(OPEN_END_FUND_REDEMPTION_CONCRETE));
    }

    function _createDefaultShareMockCalls(address currency) internal {
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotBaseInfo(uint256)", REPAYABLE_SHARE_SLOT), 
            abi.encode(governor, currency, 1704067200, 1711843200, 1704067200, true, true)
        );
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotExtInfo(uint256)", REPAYABLE_SHARE_SLOT), 
            abi.encode(governor, 100 ether, 1, 1000, true, "URI")
        );
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotTotalValue(uint256)", REPAYABLE_SHARE_SLOT),
            abi.encode(1000 ether)
        );
        vm.mockCall(
            OPEN_END_FUND_SHARE_CONCRETE, abi.encodeWithSignature("slotCurrencyBalance(uint256)", REPAYABLE_SHARE_SLOT),
            abi.encode(0)
        );
    }

    function _createDefaultRedemptionMockCalls(address currency, uint256 nav) internal {
        vm.mockCall(
            OPEN_END_FUND_REDEMPTION_CONCRETE, abi.encodeWithSignature("getRedeemInfo(uint256)", REPAYABLE_REDEMPTION_SLOT), 
            abi.encode(REPAYABLE_POOL_ID, currency, 1704067200, nav)
        );
        vm.mockCall(
            OPEN_END_FUND_REDEMPTION_CONCRETE, abi.encodeWithSignature("slotTotalValue(uint256)", REPAYABLE_REDEMPTION_SLOT),
            abi.encode(1000 ether)
        );
        vm.mockCall(
            OPEN_END_FUND_REDEMPTION_CONCRETE, abi.encodeWithSignature("slotCurrencyBalance(uint256)", REPAYABLE_REDEMPTION_SLOT),
            abi.encode(0)
        );
    }

}