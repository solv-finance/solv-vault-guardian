// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/merlinswap/MerlinSwapAuthorization.sol";
import "../../src/authorizations/merlinswap/MerlinSwapAuthorizationACL.sol";

contract MerlinSwapAuthorizationTest is AuthorizationTestBase {

    address internal constant MERLIN_SWAP = 0x1aFa5D7f89743219576Ef48a9826261bE6378a68;

    function setUp() public override {
        super.setUp();

        address[] memory tokenWhitelist = new address[](3);
        tokenWhitelist[0] = WETH;
        tokenWhitelist[1] = WBTC;
        tokenWhitelist[2] = USDT;
        _authorization = new MerlinSwapAuthorization(address(_guardian), safeAccount, MERLIN_SWAP, tokenWhitelist);
    }

    function test_AuthorizationInitialStatus() public {
        address acl = _authorization.getACLByContract(MERLIN_SWAP);
        assertNotEq(acl, address(0));
    }

    function test_SwapDesire() public {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "swapDesire((bytes,address,uint128,uint256,uint256))", 
            ISwap.SwapDesireParams(path, safeAccount, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SwapAmount() public {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "swapAmount((bytes,address,uint128,uint256,uint256))", 
            ISwap.SwapAmountParams(path, safeAccount, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SwapY2X() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2X((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SwapY2XDesireX() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2XDesireX((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SwapX2Y() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2Y((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SwapX2YDesireY() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2YDesireY((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenSwapDesireWithInvalidToken() public {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDC, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "swapDesire((bytes,address,uint128,uint256,uint256))", 
            ISwap.SwapDesireParams(path, safeAccount, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: token not allowed"));
    }

    function test_RevertWhenSwapDesireWithInvalidRecipient() public {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "swapDesire((bytes,address,uint128,uint256,uint256))", 
            ISwap.SwapDesireParams(path, permissionlessAccount, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: recipient not allowed"));
    }

    function test_RevertWhenSwapAmountWithInvalidToken() public {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDC, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "swapAmount((bytes,address,uint128,uint256,uint256))", 
            ISwap.SwapAmountParams(path, safeAccount, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: token not allowed"));
    }

    function test_RevertWhenSwapAmountWithInvalidRecipient() public {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "swapAmount((bytes,address,uint128,uint256,uint256))", 
            ISwap.SwapAmountParams(path, permissionlessAccount, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: recipient not allowed"));
    }

    function test_RevertWhenSwapY2XWithInvalidTokenX() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2X((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(USDC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenX not allowed"));
    }

    function test_RevertWhenSwapY2XWithInvalidTokenY() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2X((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDC, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenY not allowed"));
    }

    function test_RevertWhenSwapY2XWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2X((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), permissionlessAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: recipient not allowed"));
    }

    function test_RevertWhenSwapY2XDesireXWithInvalidTokenX() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2XDesireX((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(USDC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenX not allowed"));
    }

    function test_RevertWhenSwapY2XDesireXWithInvalidTokenY() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2XDesireX((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDC, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenY not allowed"));
    }

    function test_RevertWhenSwapY2XDesireXWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapY2XDesireX((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), permissionlessAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: recipient not allowed"));
    }

    function test_RevertWhenSwapX2YDesireYWithInvalidTokenX() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2YDesireY((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(USDC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenX not allowed"));
    }

    function test_RevertWhenSwapX2YDesireYWithInvalidTokenY() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2YDesireY((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDC, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenY not allowed"));
    }

    function test_RevertWhenSwapX2YDesireYWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2YDesireY((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), permissionlessAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: recipient not allowed"));
    }

    function test_RevertWhenSwapX2YWithInvalidTokenX() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2Y((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(USDC, USDT, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenX not allowed"));
    }

    function test_RevertWhenSwapX2YWithInvalidTokenY() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2Y((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDC, uint24(500), int24(800001), safeAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: tokenY not allowed"));
    }

    function test_RevertWhenSwapX2YWithInvalidRecipient() public {
        bytes memory txData = abi.encodeWithSignature(
            "swapX2Y((address,address,uint24,int24,address,uint128,uint256,uint256,uint256))", 
            ISwap.SwapParams(WBTC, USDT, uint24(500), int24(800001), permissionlessAccount, 1 ether, 1 ether, 1 ether, block.timestamp + 300)
        );
        _checkFromAuthorization(MERLIN_SWAP, 0, txData, Type.CheckResult(false, "MerlinSwapACL: recipient not allowed"));
    }


    function test_AddTokenWhitelist() public {
        MerlinSwapAuthorizationACLMock acl = new MerlinSwapAuthorizationACLMock(
            address(_guardian), safeAccount, MERLIN_SWAP, new address[](0)
        );
        acl.addTokenWhitelist(WBTC);
        assertTrue(acl.checkToken(WBTC));
        assertFalse(acl.checkToken(WETH));
    }

    function test_RevertWhenAddInvalidTokenWhitelist() public {
        MerlinSwapAuthorizationACLMock acl = new MerlinSwapAuthorizationACLMock(
            address(_guardian), safeAccount, MERLIN_SWAP, new address[](0)
        );
        vm.expectRevert("MerlinSwapACL: token cannot be the zero address");
        acl.addTokenWhitelist(address(0));
    }
}

contract MerlinSwapAuthorizationACLMock is MerlinSwapAuthorizationACL {
    constructor(
        address caller_,
        address safeAccount_,
        address merlinSwap_,
        address[] memory tokenWhitelist_
    ) 
        MerlinSwapAuthorizationACL(caller_, safeAccount_, merlinSwap_, tokenWhitelist_) {}

    function addTokenWhitelist(address token_) external {
        _addTokenWhitelist(token_);
    }

    function checkToken(address token_) external view returns (bool) {
        return _checkToken(token_);
    }
}
