// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/external/IERC3525.sol";
import "../../src/common/BaseAuthorization.sol";
import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/ERC3525Authorization.sol";

contract ERC3525AuthorizationTest is SolvVaultGuardianBaseTest {

    ERC3525Authorization internal _erc3525Authorization;

    uint256 internal _mockedShareSftId = 100;

    function setUp() public virtual override {
        super.setUp();

        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();
    }

    function test_AuthorizationInitialStatus() public virtual {
        _addDefaultERC3525Authorization();

        address[] memory approvableTokens = _erc3525Authorization.getAllTokens();
        assertEq(approvableTokens.length, 1);
        assertEq(approvableTokens[0], OPEN_END_FUND_SHARE);

        address[] memory shareAllowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 1);
        assertEq(shareAllowedSpenders[0], OPEN_END_FUND_MARKET);

        address[] memory redemptionAllowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 0);
    }

    function test_GuardianInitialStatus() public virtual {
        _addDefaultERC3525Authorization();
        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 1);
        assertEq(toAddresses[0], OPEN_END_FUND_SHARE);
    }

    function test_GuardianStatusAfterRemoved() public virtual {
        _addDefaultERC3525Authorization();
        vm.startPrank(governor);
        _guardian.removeAuthorization(OPEN_END_FUND_SHARE);
        vm.stopPrank();

        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 0);
    }

    function test_ApproveErc3525Token() public virtual {
        _addDefaultERC3525Authorization();

        address[] memory allowedTokens = _erc3525Authorization.getAllTokens();
        assertEq(allowedTokens.length, 1);
        assertEq(allowedTokens[0], OPEN_END_FUND_SHARE);

        address[] memory allowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(allowedSpenders.length, 1);
        assertEq(allowedSpenders[0], OPEN_END_FUND_MARKET);

        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, _mockedShareSftId), Enum.Operation.Call);
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, OPEN_END_FUND_MARKET, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenERC3525AuthorizationIsNotAdded() public virtual {
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, _mockedShareSftId), Enum.Operation.Call);
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, OPEN_END_FUND_MARKET, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenERC3525AuthorizationIsRemoved() public virtual {
        _addDefaultERC3525Authorization();
        address[] memory auths = new address[](1);
        auths[0] = address(_erc3525Authorization);
        vm.startPrank(governor);
        _guardian.removeAuthorization(OPEN_END_FUND_SHARE);
        vm.stopPrank();

        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, _mockedShareSftId), Enum.Operation.Call);
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, OPEN_END_FUND_MARKET, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenApproveWithUnauthorizedToken() public virtual {
        _addDefaultERC3525Authorization();
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(OPEN_END_FUND_REDEMPTION, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, _mockedShareSftId), Enum.Operation.Call);
        _checkFromGuardian(OPEN_END_FUND_REDEMPTION, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, OPEN_END_FUND_MARKET, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenApproveToUnauthorizedSpender() public virtual {
        _addDefaultERC3525Authorization();
        _revertMessage = "ERC3525Authorization: ERC3525 id spender not allowed";
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", ownerOfSafe, _mockedShareSftId), Enum.Operation.Call);
        _revertMessage = "ERC3525Authorization: ERC3525 value spender not allowed";
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", _mockedShareSftId, ownerOfSafe, 10e6), Enum.Operation.Call);
    }

    function test_UpdateTokenSpenders() public virtual {
        _addDefaultERC3525Authorization();

        address[] memory addSpenderAddresses = new address[](2);
        addSpenderAddresses[0] = OPEN_END_FUND_MARKET;
        addSpenderAddresses[1] = ownerOfSafe;
        ERC3525Authorization.TokenSpenders[] memory addTokenSpenders = new ERC3525Authorization.TokenSpenders[](2);
        addTokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, addSpenderAddresses);
        addTokenSpenders[1] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_REDEMPTION, addSpenderAddresses);

        vm.startPrank(governor);
        _erc3525Authorization.addTokenSpenders(addTokenSpenders);
        vm.stopPrank();

        address[] memory allowedTokens = _erc3525Authorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], OPEN_END_FUND_SHARE);
        assertEq(allowedTokens[1], OPEN_END_FUND_REDEMPTION);

        address[] memory shareAllowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 2);
        assertEq(shareAllowedSpenders[0], OPEN_END_FUND_MARKET);
        assertEq(shareAllowedSpenders[1], ownerOfSafe);

        address[] memory redemptionAllowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 2);
        assertEq(redemptionAllowedSpenders[0], OPEN_END_FUND_MARKET);
        assertEq(redemptionAllowedSpenders[1], ownerOfSafe);

        address[] memory revomeShareSpenderAddresses = new address[](1);
        revomeShareSpenderAddresses[0] = OPEN_END_FUND_MARKET;
        address[] memory revomeRedemptionSpenderAddresses = new address[](1);
        revomeRedemptionSpenderAddresses[0] = ownerOfSafe;
        ERC3525Authorization.TokenSpenders[] memory removeTokenSpenders = new ERC3525Authorization.TokenSpenders[](2);
        removeTokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, revomeShareSpenderAddresses);
        removeTokenSpenders[1] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_REDEMPTION, revomeRedemptionSpenderAddresses);

        vm.startPrank(governor);
        _erc3525Authorization.removeTokenSpenders(removeTokenSpenders);
        vm.stopPrank();

        allowedTokens = _erc3525Authorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], OPEN_END_FUND_SHARE);
        assertEq(allowedTokens[1], OPEN_END_FUND_REDEMPTION);

        shareAllowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_SHARE);
        assertEq(shareAllowedSpenders.length, 1);
        assertEq(shareAllowedSpenders[0], ownerOfSafe);

        redemptionAllowedSpenders = _erc3525Authorization.getTokenSpenders(OPEN_END_FUND_REDEMPTION);
        assertEq(redemptionAllowedSpenders.length, 1);
        assertEq(redemptionAllowedSpenders[0], OPEN_END_FUND_MARKET);
    }

    function test_RevertWhenUpdateTokenSpendersByNonGovernor() public virtual {
        _addDefaultERC3525Authorization();

        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_MARKET;
        ERC3525Authorization.TokenSpenders[] memory tokenSpenders = new ERC3525Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, spenderAddresses);

        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _erc3525Authorization.addTokenSpenders(tokenSpenders);
        vm.expectRevert("Governable: only governor");
        _erc3525Authorization.removeTokenSpenders(tokenSpenders);
        vm.stopPrank();
    }

    function _addDefaultERC3525Authorization() internal virtual {
        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_MARKET;
        ERC3525Authorization.TokenSpenders[] memory tokenSpenders = new ERC3525Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC3525Authorization.TokenSpenders(OPEN_END_FUND_SHARE, spenderAddresses);

        _erc3525Authorization = new ERC3525Authorization(address(_guardian), tokenSpenders);

        vm.startPrank(governor);
        _guardian.setAuthorization(OPEN_END_FUND_SHARE, address(_erc3525Authorization));
        vm.stopPrank();
    }

}
