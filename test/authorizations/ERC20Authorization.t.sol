// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/common/BaseAuthorization.sol";
import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/ERC20Authorization.sol";

contract ERC20AuthorizationTest is SolvVaultGuardianBaseTest {

    ERC20Authorization internal _erc20Authorization;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();
    }

    function test_AuthorizationInitialStatus() public virtual {
        _addDefaultERC20Authorization();
        address[] memory approvableTokens = _erc20Authorization.getAllTokens();
        assertEq(approvableTokens.length, 2);
        assertEq(approvableTokens[0], USDT);
        assertEq(approvableTokens[1], USDC);

        address[] memory usdtAllowedSpenders = _erc20Authorization.getTokenSpenders(USDT);
        assertEq(usdtAllowedSpenders.length, 1);
        assertEq(usdtAllowedSpenders[0], OPEN_END_FUND_SHARE);

        address[] memory usdtAllowedReceivers = _erc20Authorization.getTokenReceivers(USDT);
        assertEq(usdtAllowedReceivers.length, 0);

        address[] memory usdcAllowedSpenders = _erc20Authorization.getTokenSpenders(USDC);
        assertEq(usdcAllowedSpenders.length, 0);

        address[] memory usdcAllowedReceivers = _erc20Authorization.getTokenReceivers(USDC);
        assertEq(usdcAllowedReceivers.length, 1);
        assertEq(usdcAllowedReceivers[0], OPEN_END_FUND_REDEMPTION);
    }

    function test_GuardianInitialStatus() public virtual {
        _addDefaultERC20Authorization();
        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 2);
        assertEq(toAddresses[0], USDT);
        assertEq(toAddresses[1], USDC);
    }

    function test_GuardianStatusAfterRemovedOne() public virtual {
        _addDefaultERC20Authorization();
        vm.startPrank(governor);
        _guardian.removeAuthorization(USDT);
        vm.stopPrank();

        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 1);
        assertEq(toAddresses[0], USDC);
    }

    function test_ApproveErc20Token() public virtual {
        _addDefaultERC20Authorization();
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
    }

    function test_TransferErc20Token() public virtual {
        _addDefaultERC20Authorization();
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenERC20AuthorizationIsNotAdded() public virtual {
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenERC20AuthorizationForApprovalIsRemoved() public virtual {
        _addDefaultERC20Authorization();
        vm.startPrank(governor);
        _guardian.removeAuthorization(USDT);
        vm.stopPrank();

        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
        
        _revertMessage = "FunctionAuthorization: not allowed function";
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        
        _revertMessage = "";
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenERC20AuthorizationForTransferIsRemoved() public virtual {
        _addDefaultERC20Authorization();
        vm.startPrank(governor);
        _guardian.removeAuthorization(USDC);
        vm.stopPrank();

        _revertMessage = "";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        
        _revertMessage = "FunctionAuthorization: not allowed function";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
        
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenApproveUnauthorizedToken() public virtual {
        _addDefaultERC20Authorization();
        _revertMessage = "FunctionAuthorization: not allowed function";
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenApproveToUnauthorizedSpender() public virtual {
        _addDefaultERC20Authorization();
        _revertMessage = "ERC20Authorization: ERC20 spender not allowed";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("approve(address,uint256)", ownerOfSafe, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", ownerOfSafe, 10e6), Enum.Operation.Call);
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", ownerOfSafe, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenTransferUnauthorizedToken() public virtual {
        _addDefaultERC20Authorization();
        _revertMessage = "FunctionAuthorization: not allowed function";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), Enum.Operation.Call);
    }

    function test_RevertWhenTransferToUnauthorizedReceiver() public virtual {
        _addDefaultERC20Authorization();
        _revertMessage = "ERC20Authorization: ERC20 receiver not allowed";
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", ownerOfSafe, 10e6), Enum.Operation.Call);
    }

    function test_UpdateTokenSpenders() public virtual {
        _addDefaultERC20Authorization();

        address[] memory addSpenderAddresses = new address[](2);
        addSpenderAddresses[0] = OPEN_END_FUND_SHARE;
        addSpenderAddresses[1] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenSpenders[] memory addTokenSpenders = new ERC20Authorization.TokenSpenders[](2);
        addTokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, addSpenderAddresses);
        addTokenSpenders[1] = ERC20Authorization.TokenSpenders(USDC, addSpenderAddresses);

        vm.startPrank(governor);
        _erc20Authorization.addTokenSpenders(addTokenSpenders);
        vm.stopPrank();

        address[] memory allowedTokens = _erc20Authorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], USDT);
        assertEq(allowedTokens[1], USDC);

        address[] memory usdtAllowedSpenders = _erc20Authorization.getTokenSpenders(USDT);
        assertEq(usdtAllowedSpenders.length, 2);
        assertEq(usdtAllowedSpenders[0], OPEN_END_FUND_SHARE);
        assertEq(usdtAllowedSpenders[1], OPEN_END_FUND_REDEMPTION);

        address[] memory usdcAllowedSpenders = _erc20Authorization.getTokenSpenders(USDC);
        assertEq(usdcAllowedSpenders.length, 2);
        assertEq(usdcAllowedSpenders[0], OPEN_END_FUND_SHARE);
        assertEq(usdcAllowedSpenders[1], OPEN_END_FUND_REDEMPTION);

        address[] memory revomeUsdtSpenderAddresses = new address[](1);
        revomeUsdtSpenderAddresses[0] = OPEN_END_FUND_SHARE;
        address[] memory revomeUsdcSpenderAddresses = new address[](1);
        revomeUsdcSpenderAddresses[0] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenSpenders[] memory removeTokenSpenders = new ERC20Authorization.TokenSpenders[](2);
        removeTokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, revomeUsdtSpenderAddresses);
        removeTokenSpenders[1] = ERC20Authorization.TokenSpenders(USDC, revomeUsdcSpenderAddresses);

        vm.startPrank(governor);
        _erc20Authorization.removeTokenSpenders(removeTokenSpenders);
        vm.stopPrank();

        allowedTokens = _erc20Authorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], USDT);
        assertEq(allowedTokens[1], USDC);

        usdtAllowedSpenders = _erc20Authorization.getTokenSpenders(USDT);
        assertEq(usdtAllowedSpenders.length, 1);
        assertEq(usdtAllowedSpenders[0], OPEN_END_FUND_REDEMPTION);

        usdcAllowedSpenders = _erc20Authorization.getTokenSpenders(USDC);
        assertEq(usdcAllowedSpenders.length, 1);
        assertEq(usdcAllowedSpenders[0], OPEN_END_FUND_SHARE);
    }

    function test_UpdateTokenReceivers() public virtual {
        _addDefaultERC20Authorization();

        address[] memory addReceiverAddresses = new address[](2);
        addReceiverAddresses[0] = OPEN_END_FUND_SHARE;
        addReceiverAddresses[1] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory addTokenReceivers = new ERC20Authorization.TokenReceivers[](2);
        addTokenReceivers[0] = ERC20Authorization.TokenReceivers(USDT, addReceiverAddresses);
        addTokenReceivers[1] = ERC20Authorization.TokenReceivers(USDC, addReceiverAddresses);

        vm.startPrank(governor);
        _erc20Authorization.addTokenReceivers(addTokenReceivers);
        vm.stopPrank();

        address[] memory allowedTokens = _erc20Authorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], USDT);
        assertEq(allowedTokens[1], USDC);

        address[] memory usdtAllowedReceivers = _erc20Authorization.getTokenReceivers(USDT);
        assertEq(usdtAllowedReceivers.length, 2);
        assertEq(usdtAllowedReceivers[0], OPEN_END_FUND_SHARE);
        assertEq(usdtAllowedReceivers[1], OPEN_END_FUND_REDEMPTION);

        address[] memory usdcAllowedReceivers = _erc20Authorization.getTokenReceivers(USDC);
        assertEq(usdcAllowedReceivers.length, 2);
        assertEq(usdcAllowedReceivers[0], OPEN_END_FUND_REDEMPTION);
        assertEq(usdcAllowedReceivers[1], OPEN_END_FUND_SHARE);

        address[] memory revomeUsdtReceiverAddresses = new address[](1);
        revomeUsdtReceiverAddresses[0] = OPEN_END_FUND_SHARE;
        address[] memory revomeUsdcReceiverAddresses = new address[](1);
        revomeUsdcReceiverAddresses[0] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory removeTokenReceivers = new ERC20Authorization.TokenReceivers[](2);
        removeTokenReceivers[0] = ERC20Authorization.TokenReceivers(USDT, revomeUsdtReceiverAddresses);
        removeTokenReceivers[1] = ERC20Authorization.TokenReceivers(USDC, revomeUsdcReceiverAddresses);

        vm.startPrank(governor);
        _erc20Authorization.removeTokenReceivers(removeTokenReceivers);
        vm.stopPrank();

        allowedTokens = _erc20Authorization.getAllTokens();
        assertEq(allowedTokens.length, 2);
        assertEq(allowedTokens[0], USDT);
        assertEq(allowedTokens[1], USDC);

        usdtAllowedReceivers = _erc20Authorization.getTokenReceivers(USDT);
        assertEq(usdtAllowedReceivers.length, 1);
        assertEq(usdtAllowedReceivers[0], OPEN_END_FUND_REDEMPTION);

        usdcAllowedReceivers = _erc20Authorization.getTokenReceivers(USDC);
        assertEq(usdcAllowedReceivers.length, 1);
        assertEq(usdcAllowedReceivers[0], OPEN_END_FUND_SHARE);
    }

    function test_RevertWhenUpdateTokenSpendersByNonGovernor() public virtual {
        _addDefaultERC20Authorization();

        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_SHARE;
        ERC20Authorization.TokenSpenders[] memory tokenSpenders = new ERC20Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, spenderAddresses);

        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _erc20Authorization.addTokenSpenders(tokenSpenders);
        vm.expectRevert("Governable: only governor");
        _erc20Authorization.removeTokenSpenders(tokenSpenders);
        vm.stopPrank();
    }

    function test_RevertWhenUpdateTokenReceiversByNonGovernor() public virtual {
        _addDefaultERC20Authorization();

        address[] memory receiverAddresses = new address[](1);
        receiverAddresses[0] = OPEN_END_FUND_SHARE;
        ERC20Authorization.TokenReceivers[] memory tokenReceivers = new ERC20Authorization.TokenReceivers[](1);
        tokenReceivers[0] = ERC20Authorization.TokenReceivers(USDT, receiverAddresses);

        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _erc20Authorization.addTokenReceivers(tokenReceivers);
        vm.expectRevert("Governable: only governor");
        _erc20Authorization.removeTokenReceivers(tokenReceivers);
        vm.stopPrank();
    }

    function _addDefaultERC20Authorization() internal virtual {
        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_SHARE;
        ERC20Authorization.TokenSpenders[] memory tokenSpenders = new ERC20Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, spenderAddresses);

        address[] memory receiverAddresses = new address[](1);
        receiverAddresses[0] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory tokenReceivers = new ERC20Authorization.TokenReceivers[](1);
        tokenReceivers[0] = ERC20Authorization.TokenReceivers(USDC, receiverAddresses);

        _erc20Authorization = new ERC20Authorization(
            address(_guardian), tokenSpenders, tokenReceivers
        );

        vm.startPrank(governor);
        _guardian.setAuthorization(USDT, address(_erc20Authorization));
        _guardian.setAuthorization(USDC, address(_erc20Authorization));
        vm.stopPrank();
    }

}
