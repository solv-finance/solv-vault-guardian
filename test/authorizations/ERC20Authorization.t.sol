// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/ERC20Authorization.sol";

contract ERC20AuthorizationTest is AuthorizationTestBase {

    ERC20Authorization internal _erc20Authorization;

    function setUp() public virtual override {
        super.setUp();

        address[] memory spenderAddresses = new address[](1);
        spenderAddresses[0] = OPEN_END_FUND_SHARE;
        ERC20Authorization.TokenSpenders[] memory tokenSpenders = new ERC20Authorization.TokenSpenders[](1);
        tokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, spenderAddresses);

        address[] memory receiverAddresses = new address[](1);
        receiverAddresses[0] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory tokenReceivers = new ERC20Authorization.TokenReceivers[](1);
        tokenReceivers[0] = ERC20Authorization.TokenReceivers(USDC, receiverAddresses);

        _erc20Authorization = new ERC20Authorization(address(_guardian), tokenSpenders, tokenReceivers);
        _authorization = _erc20Authorization;
    }
    
    function test_AuthorizationInitialStatus() public virtual {
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

    function test_ApproveErc20Token() public virtual {
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), 
            Type.CheckResult(true, "")
        );
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), 
            Type.CheckResult(true, "")
        );
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), 
            Type.CheckResult(true, "")
        );
    }

    function test_TransferErc20Token() public virtual {
        _checkFromAuthorization(
            USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6), 
            Type.CheckResult(true, "")
        );
    }

    function test_RevertWhenApproveUnauthorizedToken() public virtual {
        _checkFromAuthorization(
            USDC, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_SHARE, 10e6), 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
        _checkFromAuthorization(
            USDC, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
        _checkFromAuthorization(
            USDC, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", OPEN_END_FUND_SHARE, 10e6), 
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenApproveToUnauthorizedSpender() public virtual {
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("approve(address,uint256)", ownerOfSafe, 10e6),
            Type.CheckResult(false, "ERC20Authorization: ERC20 spender not allowed")
        );
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("increaseAllowance(address,uint256)", ownerOfSafe, 10e6),
            Type.CheckResult(false, "ERC20Authorization: ERC20 spender not allowed")
        );
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("decreaseAllowance(address,uint256)", ownerOfSafe, 10e6),
            Type.CheckResult(false, "ERC20Authorization: ERC20 spender not allowed")
        );
    }

    function test_RevertWhenTransferUnauthorizedToken() public virtual {
        _checkFromAuthorization(
            USDT, 0, abi.encodeWithSignature("transfer(address,uint256)", OPEN_END_FUND_REDEMPTION, 10e6),
            Type.CheckResult(false, "FunctionAuthorization: not allowed function")
        );
    }

    function test_RevertWhenTransferToUnauthorizedReceiver() public virtual {
        _checkFromAuthorization(
            USDC, 0, abi.encodeWithSignature("transfer(address,uint256)", ownerOfSafe, 10e6),
            Type.CheckResult(false, "ERC20Authorization: ERC20 receiver not allowed")
        );
    }

    function test_UpdateTokenSpenders() public virtual {
        _erc20Authorization = new ERC20Authorization(
            address(_guardian), new ERC20Authorization.TokenSpenders[](0), new ERC20Authorization.TokenReceivers[](0)
        );
        vm.startPrank(governor);

        address[] memory addSpenderAddresses = new address[](2);
        addSpenderAddresses[0] = OPEN_END_FUND_SHARE;
        addSpenderAddresses[1] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenSpenders[] memory addTokenSpenders = new ERC20Authorization.TokenSpenders[](2);
        addTokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, addSpenderAddresses);
        addTokenSpenders[1] = ERC20Authorization.TokenSpenders(USDC, addSpenderAddresses);
        _erc20Authorization.addTokenSpenders(addTokenSpenders);

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

        _erc20Authorization.removeTokenSpenders(removeTokenSpenders);

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
     
        vm.stopPrank();
    }

    function test_UpdateTokenReceivers() public virtual {
        _erc20Authorization = new ERC20Authorization(
            address(_guardian), new ERC20Authorization.TokenSpenders[](0), new ERC20Authorization.TokenReceivers[](0)
        );
        vm.startPrank(governor);

        address[] memory addReceiverAddresses = new address[](2);
        addReceiverAddresses[0] = OPEN_END_FUND_SHARE;
        addReceiverAddresses[1] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory addTokenReceivers = new ERC20Authorization.TokenReceivers[](2);
        addTokenReceivers[0] = ERC20Authorization.TokenReceivers(USDT, addReceiverAddresses);
        addTokenReceivers[1] = ERC20Authorization.TokenReceivers(USDC, addReceiverAddresses);
        _erc20Authorization.addTokenReceivers(addTokenReceivers);

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
        assertEq(usdcAllowedReceivers[0], OPEN_END_FUND_SHARE);
        assertEq(usdcAllowedReceivers[1], OPEN_END_FUND_REDEMPTION);

        address[] memory revomeUsdtReceiverAddresses = new address[](1);
        revomeUsdtReceiverAddresses[0] = OPEN_END_FUND_SHARE;
        address[] memory revomeUsdcReceiverAddresses = new address[](1);
        revomeUsdcReceiverAddresses[0] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory removeTokenReceivers = new ERC20Authorization.TokenReceivers[](2);
        removeTokenReceivers[0] = ERC20Authorization.TokenReceivers(USDT, revomeUsdtReceiverAddresses);
        removeTokenReceivers[1] = ERC20Authorization.TokenReceivers(USDC, revomeUsdcReceiverAddresses);
        _erc20Authorization.removeTokenReceivers(removeTokenReceivers);

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

        vm.stopPrank();
    }

    function test_RemoveToken() public virtual {
        _erc20Authorization = new ERC20Authorization(
            address(_guardian), new ERC20Authorization.TokenSpenders[](0), new ERC20Authorization.TokenReceivers[](0)
        );
        vm.startPrank(governor);

        address[] memory addSpenderAddresses = new address[](2);
        addSpenderAddresses[0] = OPEN_END_FUND_SHARE;
        addSpenderAddresses[1] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenSpenders[] memory addTokenSpenders = new ERC20Authorization.TokenSpenders[](2);
        addTokenSpenders[0] = ERC20Authorization.TokenSpenders(USDT, addSpenderAddresses);
        addTokenSpenders[1] = ERC20Authorization.TokenSpenders(USDC, addSpenderAddresses);
        _erc20Authorization.addTokenSpenders(addTokenSpenders);

        address[] memory addReceiverAddresses = new address[](2);
        addReceiverAddresses[0] = OPEN_END_FUND_SHARE;
        addReceiverAddresses[1] = OPEN_END_FUND_REDEMPTION;
        ERC20Authorization.TokenReceivers[] memory addTokenReceivers = new ERC20Authorization.TokenReceivers[](2);
        addTokenReceivers[0] = ERC20Authorization.TokenReceivers(USDT, addReceiverAddresses);
        addTokenReceivers[1] = ERC20Authorization.TokenReceivers(USDC, addReceiverAddresses);
        _erc20Authorization.addTokenReceivers(addTokenReceivers);

        _erc20Authorization.removeToken(USDC);
        
        address[] memory allowedTokens = _erc20Authorization.getAllTokens();
        assertEq(allowedTokens.length, 1);
        assertEq(allowedTokens[0], USDT);

        address[] memory usdtAllowedSpenders = _erc20Authorization.getTokenReceivers(USDT);
        assertEq(usdtAllowedSpenders.length, 2);
        assertEq(usdtAllowedSpenders[0], OPEN_END_FUND_SHARE);
        assertEq(usdtAllowedSpenders[1], OPEN_END_FUND_REDEMPTION);

        address[] memory usdtAllowedReceivers = _erc20Authorization.getTokenReceivers(USDT);
        assertEq(usdtAllowedReceivers.length, 2);
        assertEq(usdtAllowedReceivers[0], OPEN_END_FUND_SHARE);
        assertEq(usdtAllowedReceivers[1], OPEN_END_FUND_REDEMPTION);

        address[] memory usdcAllowedSpenders = _erc20Authorization.getTokenSpenders(USDC);
        assertEq(usdcAllowedSpenders.length, 0);

        address[] memory usdcAllowedReceivers = _erc20Authorization.getTokenReceivers(USDC);
        assertEq(usdcAllowedReceivers.length, 0);

        vm.stopPrank();
    }

    function test_RevertWhenUpdateTokenSpendersByNonGovernor() public virtual {
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

}
