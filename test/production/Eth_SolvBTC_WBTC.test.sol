// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/SolvVaultGuardianForSafe13.sol";
import {MultiSend} from "safe-contracts-1.3.0/libraries/MultiSend.sol";
import {GnosisSafeL2} from "safe-contracts-1.3.0/GnosisSafeL2.sol";
import {GnosisSafeProxy} from "safe-contracts-1.3.0/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "safe-contracts-1.3.0/proxies/GnosisSafeProxyFactory.sol";
import {SolvVaultGuardianForSafe13Test} from "../integration/SolvVaultGuardianForSafe13.t.sol";

contract Eth_SolvBTC_WBTC_Test is Test {

    address payable internal safeAccount;
    address internal safeOwner;
    uint256 internal safeOwnerPrivKey;
    address internal guardian;

    address internal erc20 = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal share = 0x7d6C3860B71CF82e2e1E8d5D104CF77f5B84f93a;
    address internal redemption = 0x1D0Db695F3033875d1b6A0155c38B3EE2AEd3082;

    function setUp() public virtual {
        safeAccount = payable(0x9Bc8EF6bb09e3D0F3F3a6CD02D2B9dC3115C7c5C);
        (safeOwner, safeOwnerPrivKey) = makeAddrAndKey("SAFE_OWNER");
        guardian = 0x8c0Dd8cC91e24c7cba3f2F301e7702E9d6E9d45F;
        _setOwner();
    }

    function test_RemoveAfterSettingGuard() public {
        _setGuard();
        vm.startPrank(safeOwner);
        _callExecTransaction(safeAccount, 0, abi.encodeWithSignature("setGuard(address)", address(0)));
        bytes memory guardBytes = GnosisSafeL2(safeAccount).getStorageAt(0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8, 1);
        require(address(0) == abi.decode(guardBytes, (address)), "guardian not removed");
        vm.stopPrank();
    }

    function test_ApproveAfterSettingGuard() public {
        _setGuard();
        vm.startPrank(safeOwner);
        _callExecTransaction(erc20, 0, abi.encodeWithSignature("approve(address,uint256)", share, 1 ether));
        _callExecTransactionShouldRevert(erc20, 0, abi.encodeWithSignature("approve(address,uint256)", safeOwner, 1 ether), "ERC20Authorization: ERC20 spender not allowed");
        vm.stopPrank();
    }

    function test_TransferAfterSettingGuard() public {
        _setGuard();
        vm.startPrank(safeOwner);
        _callExecTransactionShouldRevert(erc20, 0, abi.encodeWithSignature("transfer(address,uint256)", safeOwner, 1 ether), "FunctionAuthorization: not allowed function");
        vm.stopPrank();
    }

    function _setOwner() internal {
        vm.startPrank(safeAccount);
        GnosisSafeL2(safeAccount).addOwnerWithThreshold(safeOwner, 1);
        vm.stopPrank();
    }

    function _setGuard() internal {
        vm.startPrank(safeOwner);
        _callExecTransaction(safeAccount, 0, abi.encodeWithSignature("setGuard(address)", guardian));
        bytes memory guardBytes = GnosisSafeL2(safeAccount).getStorageAt(0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8, 1);
        require(guardian == abi.decode(guardBytes, (address)), "guardian not set");
        vm.stopPrank();
    }


    function _callExecTransaction(address contract_, uint256 value_, bytes memory data_) internal {
        Enum.Operation operation_ = Enum.Operation.Call;
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        GnosisSafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _callExecTransactionShouldRevert(
        address contract_,
        uint256 value_,
        bytes memory data_,
        bytes memory revertMessage_
    ) internal virtual {
        Enum.Operation operation_ = Enum.Operation.Call;
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        vm.expectRevert(revertMessage_);
        GnosisSafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _getSignature(address contract_, uint256 value_, bytes memory data_, Enum.Operation operation_)
        internal
        view
        returns (bytes memory)
    {
        uint256 nonce = GnosisSafeL2(safeAccount).nonce();
        bytes memory txHashData = GnosisSafeL2(safeAccount).encodeTransactionData(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), nonce
        );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(safeOwnerPrivKey, txHash);
        return bytes.concat(r, s, bytes1(v));
    }
}