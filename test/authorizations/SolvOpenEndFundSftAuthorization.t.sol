// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/solv-open-end-fund/SolvOpenEndFundSftAuthorization.sol";

contract SolvOpenEndFundSftAuthorizationTest is AuthorizationTestBase {

    SolvOpenEndFundSftAuthorization internal _solvOpenEndFundSftAuthorization;

    uint256 internal _mockedShareSftId = 100;

    function setUp() public virtual override {
        super.setUp();

        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_MARKET;
        ERC3525Authorization.TokenSpenders[] memory tokenSpenders = new ERC3525Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, spenderAddresses);

        _solvOpenEndFundSftAuthorization = new SolvOpenEndFundSftAuthorization(
            address(_guardian), safeAccount, OPEN_END_FUND_REDEMPTION, tokenSpenders
        );
        _authorization = _solvOpenEndFundSftAuthorization;
    }

    function test_AuthorizationInitialStatus() public virtual {
        address[] memory approvableTokens = _solvOpenEndFundSftAuthorization.getAllTokens();
        assertEq(approvableTokens.length, 1);
        assertEq(approvableTokens[0], OPEN_END_FUND_SHARE);

        address[] memory shareAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 1);
        assertEq(shareAllowedSpenders[0], OPEN_END_FUND_MARKET);

        address[] memory redemptionAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 0);
    }

    function test_ApproveErc3525Token() public virtual {
        address[] memory allowedTokens = _solvOpenEndFundSftAuthorization.getAllTokens();
        assertEq(allowedTokens.length, 1);
        assertEq(allowedTokens[0], OPEN_END_FUND_SHARE);

        address[] memory allowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(allowedSpenders.length, 1);
        assertEq(allowedSpenders[0], OPEN_END_FUND_MARKET);

        _checkFromAuthorization(
            OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, _mockedShareSftId), 
            Type.CheckResult(true, "")
        );
        _checkFromAuthorization(
            OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, OPEN_END_FUND_MARKET, 10e6), 
            Type.CheckResult(true, "")
        );
    }

    function test_claim() public virtual {
         _checkFromAuthorization(
            OPEN_END_FUND_REDEMPTION, 0, abi.encodeWithSignature("claimTo(address,uint256,address,uint256)", safeAccount, _mockedShareSftId, USDT, 100e6), 
            Type.CheckResult(true, "")
        );
    }

    function test_RevertWhenApproveWithUnauthorizedToken() public virtual {
        _checkFromAuthorization(
            OPEN_END_FUND_REDEMPTION, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, _mockedShareSftId), 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
        _checkFromAuthorization(
            OPEN_END_FUND_REDEMPTION, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, OPEN_END_FUND_MARKET, 10e6), 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenApproveToUnauthorizedSpender() public virtual {
        _checkFromAuthorization(
            OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", ownerOfSafe, _mockedShareSftId), 
            Type.CheckResult(false, "ERC3525Authorization: ERC3525 id spender not allowed")
        );
        _checkFromAuthorization(
            OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, ownerOfSafe, 10e6), 
            Type.CheckResult(false, "ERC3525Authorization: ERC3525 value spender not allowed")
        );
    }

    function test_RevertWhenClaimUnthorizedSft() public virtual {
         _checkFromAuthorization(
            OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("claimTo(address,uint256,address,uint256)", safeAccount, _mockedShareSftId, USDT, 100e6), 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenClaimToInvalidReceiver() public virtual {
         _checkFromAuthorization(
            OPEN_END_FUND_REDEMPTION, 0, abi.encodeWithSignature("claimTo(address,uint256,address,uint256)", permissionlessAccount, _mockedShareSftId, USDT, 100e6), 
            Type.CheckResult(false, "SolvOpenEndFundSftAuthorizationACL: to not allowed")
        );
    }

    function test_UpdateTokenSpenders() public virtual {
        _solvOpenEndFundSftAuthorization = new SolvOpenEndFundSftAuthorization(
            address(_guardian), safeAccount, OPEN_END_FUND_REDEMPTION, new ERC3525Authorization.TokenSpenders[](0)
        );
        vm.startPrank(governor);

        // add allowed spenders
        address[] memory addSpenderAddresses = new address[](2);
        addSpenderAddresses[0] = OPEN_END_FUND_MARKET;
        addSpenderAddresses[1] = ownerOfSafe;
        ERC3525Authorization.TokenSpenders[] memory addTokenSpenders = new ERC3525Authorization.TokenSpenders[](2);
        addTokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, addSpenderAddresses);
        addTokenSpenders[1] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_REDEMPTION, addSpenderAddresses);
        _solvOpenEndFundSftAuthorization.addTokenSpenders(addTokenSpenders);

        address[] memory allowedTokens = _solvOpenEndFundSftAuthorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], OPEN_END_FUND_SHARE);
        assertEq(allowedTokens[1], OPEN_END_FUND_REDEMPTION);

        address[] memory shareAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 2);
        assertEq(shareAllowedSpenders[0], OPEN_END_FUND_MARKET);
        assertEq(shareAllowedSpenders[1], ownerOfSafe);

        address[] memory redemptionAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 2);
        assertEq(redemptionAllowedSpenders[0], OPEN_END_FUND_MARKET);
        assertEq(redemptionAllowedSpenders[1], ownerOfSafe);

        // remove allowed spenders
        address[] memory revomeSpenderAddresses = new address[](2);
        revomeSpenderAddresses[0] = OPEN_END_FUND_MARKET;
        revomeSpenderAddresses[1] = ownerOfSafe;
        ERC3525Authorization.TokenSpenders[] memory removeTokenSpenders = new ERC3525Authorization.TokenSpenders[](1);
        removeTokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, revomeSpenderAddresses);
        _solvOpenEndFundSftAuthorization.removeTokenSpenders(removeTokenSpenders);

        allowedTokens = _solvOpenEndFundSftAuthorization.getAllTokens();
        assertEq(allowedTokens.length, 1);
        assertEq(allowedTokens[0], OPEN_END_FUND_REDEMPTION);

        shareAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 0);

        redemptionAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 2);
        assertEq(redemptionAllowedSpenders[0], OPEN_END_FUND_MARKET);
        assertEq(redemptionAllowedSpenders[1], ownerOfSafe);

        // remove all allowed spenders
        removeTokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_REDEMPTION, revomeSpenderAddresses);
        _solvOpenEndFundSftAuthorization.removeTokenSpenders(removeTokenSpenders);

        allowedTokens = _solvOpenEndFundSftAuthorization.getAllTokens();
        assertEq(allowedTokens.length, 0);
        shareAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 0);
        redemptionAllowedSpenders = _solvOpenEndFundSftAuthorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 0);
        
        vm.stopPrank();
    }

    function test_RevertWhenUpdateTokenSpendersByNonGovernor() public virtual {
        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_MARKET;
        ERC3525Authorization.TokenSpenders[] memory tokenSpenders = new ERC3525Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, spenderAddresses);

        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _solvOpenEndFundSftAuthorization.addTokenSpenders(tokenSpenders);
        vm.expectRevert("Governable: only governor");
        _solvOpenEndFundSftAuthorization.removeTokenSpenders(tokenSpenders);
        vm.stopPrank();
    }

}
