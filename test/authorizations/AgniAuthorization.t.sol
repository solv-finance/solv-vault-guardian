// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/agni/AgniAuthorization.sol";
import "../../src/authorizations/agni/AgniAuthorizationACL.sol";

contract AgniAuthorizationTest is SolvVaultGuardianBaseTest {

    address internal constant AGNI_SWAP_ROUTER = 0x319B69888b0d11cEC22caA5034e25FfFBDc88421;

    AgniAuthorization internal _agniAuthorization;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        address[] memory swapTokenWhitelist = new address[](3);
        swapTokenWhitelist[0] = WETH;
        swapTokenWhitelist[1] = WBTC;
        swapTokenWhitelist[2] = USDT;
        _agniAuthorization = new AgniAuthorization(address(_guardian), safeAccount, AGNI_SWAP_ROUTER, swapTokenWhitelist);
        _addAgniAuthorization();
    }

    function test_AuthorizationInitialStatus() public virtual {
        address acl = _agniAuthorization.getACLByContract(AGNI_SWAP_ROUTER);
        assertNotEq(acl, address(0));
    }

    function test_GuardianInitialStatus() public virtual {
        address[] memory toAddresses = _guardian.getAllToAddresses();
        assertEq(toAddresses.length, 1);
        assertEq(toAddresses[0], AGNI_SWAP_ROUTER);
    }

    function test_ExactInputSingleParams() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDT, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_ExactInput() public virtual {
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputSingleParamsWithEthValue() public virtual {
        _revertMessage = "Value not zero";
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDT, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 1 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputSingleParamsWithInvalidRecipient() public virtual {
        _revertMessage = "AgniACL: recipient not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDT, 0, permissionlessAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputSingleParamsWithInvalidTokenIn() public virtual {
        _revertMessage = "AgniACL: tokenIn not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(USDC, WETH, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputSingleParamsWithInvalidTokenOut() public virtual {
        _revertMessage = "AgniACL: tokenOut not allowed";
        bytes memory txData = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))", 
            ExactInputSingleParams(WETH, USDC, 0, safeAccount, block.timestamp + 300, 1 ether, 1 ether, 1 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputWithEthValue() public virtual {
        _revertMessage = "Value not zero";
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 1 gwei, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputWithInvalidRecipient() public virtual {
        _revertMessage = "AgniACL: recipient not allowed";
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, permissionlessAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputWithInvalidTokenIn() public virtual {
        _revertMessage = "AgniACL: tokenIn not allowed";
        bytes memory path = abi.encodePacked(USDC, uint24(500), USDT, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputWithInvalidTokenOut() public virtual {
        _revertMessage = "AgniACL: tokenOut not allowed";
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), USDC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function test_RevertWhenExactInputWithInvalidTokenInBetween() public virtual {
        _revertMessage = "AgniACL: tokenOut not allowed";
        bytes memory path = abi.encodePacked(WETH, uint24(500), USDC, uint24(500), WBTC);
        bytes memory txData = abi.encodeWithSignature(
            "exactInput((bytes,address,uint256,uint256,uint256))", 
            ExactInputParams(path, safeAccount, block.timestamp + 300, 1 ether, 0.05 ether)
        );
        _checkFromGuardian(AGNI_SWAP_ROUTER, 0, txData, Enum.Operation.Call);
    }

    function _addAgniAuthorization() internal virtual {
        vm.startPrank(governor);
        _guardian.setAuthorization(AGNI_SWAP_ROUTER, address(_agniAuthorization));
        vm.stopPrank();
    }

}
