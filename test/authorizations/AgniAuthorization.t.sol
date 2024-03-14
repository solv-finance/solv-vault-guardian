// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/agni/AgniAuthorization.sol";
import "../../src/authorizations/agni/AgniAuthorizationACL.sol";

contract AgniAuthorizationTest is AuthorizationTestBase {

    address internal constant AGNI_SWAP_ROUTER = 0x319B69888b0d11cEC22caA5034e25FfFBDc88421;

    function setUp() public virtual override {
        super.setUp();

        address[] memory swapTokenWhitelist = new address[](3);
        swapTokenWhitelist[0] = WETH;
        swapTokenWhitelist[1] = WBTC;
        swapTokenWhitelist[2] = USDT;
        _authorization = new AgniAuthorization(address(_guardian), safeAccount, AGNI_SWAP_ROUTER, swapTokenWhitelist);
    }

    function test_AuthorizationInitialStatus() public virtual {
        address acl = _authorization.getACLByContract(AGNI_SWAP_ROUTER);
        assertNotEq(acl, address(0));
    }

    function test_ExactInputSingleParams() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDT, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_ExactInput() public virtual {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenExactInputSingleParamsWithEthValue() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDT, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 1 gwei, txData, Type.CheckResult(false, "Value not zero"));
    }

    function test_RevertWhenExactInputSingleParamsWithInvalidRecipient() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDT, 0, permissionlessAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: recipient not allowed"));
    }

    function test_RevertWhenExactInputSingleParamsWithInvalidTokenIn() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(USDC, WETH, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: tokenIn not allowed"));
    }

    function test_RevertWhenExactInputSingleParamsWithInvalidTokenOut() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDC, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: tokenOut not allowed"));
    }

    function test_RevertWhenExactInputWithEthValue() public virtual {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 1 gwei, txData, Type.CheckResult(false, "Value not zero"));
    }

    function test_RevertWhenExactInputWithInvalidRecipient() public virtual {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, permissionlessAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: recipient not allowed"));
    }

    function test_RevertWhenExactInputWithInvalidTokenIn() public virtual {
        bytes memory path = abi.encodePacked(USDC, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: tokenIn not allowed"));
    }

    function test_RevertWhenExactInputWithInvalidTokenOut() public virtual {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), USDC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: tokenOut not allowed"));
    }

    function test_RevertWhenExactInputWithInvalidTokenInBetween() public virtual {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDC, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromAuthorization(AGNI_SWAP_ROUTER, 0, txData, Type.CheckResult(false, "AgniACL: tokenOut not allowed"));
    }

    function test_AddTokenWhitelist() public virtual {
        AgniAuthorizationACLMock acl = new AgniAuthorizationACLMock(
            address(_guardian), safeAccount, AGNI_SWAP_ROUTER, new address[](0)
        );
        acl.addTokenWhitelist(WBTC);
        assertTrue(acl.checkToken(WBTC));
        assertFalse(acl.checkToken(WETH));
    }

    function test_RevertWhenAddInvalidTokenWhitelist() public virtual {
        AgniAuthorizationACLMock acl = new AgniAuthorizationACLMock(
            address(_guardian), safeAccount, AGNI_SWAP_ROUTER, new address[](0)
        );
        vm.expectRevert("AgniACL: token cannot be the zero address");
        acl.addTokenWhitelist(address(0));
    }
}

contract AgniAuthorizationACLMock is AgniAuthorizationACL {
    constructor(
        address caller_,
        address safeAccount_,
        address agniSwapRouter_,
        address[] memory tokenWhitelist_
    ) 
        AgniAuthorizationACL(caller_, safeAccount_, agniSwapRouter_, tokenWhitelist_) {}

    function addTokenWhitelist(address token_) external virtual {
        _addTokenWhitelist(token_);
    }

    function checkToken(address token_) external virtual returns (bool) {
        return _checkToken(token_);
    }
}
