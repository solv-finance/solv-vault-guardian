// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./SolvVaultGuardianTestCommonCase.sol";
import "../../src/SolvVaultGuardianForSafe14.sol";
import {MultiSend} from "safe-contracts-1.4.0/libraries/MultiSend.sol";
import {SafeL2} from "safe-contracts-1.4.0/SafeL2.sol";
import {SafeProxy} from "safe-contracts-1.4.0/proxies/SafeProxy.sol";
import {SafeProxyFactory} from "safe-contracts-1.4.0/proxies/SafeProxyFactory.sol";

contract SolvVaultGuardianForSafe14Test is SolvVaultGuardianTestCommonCase {
    function setUp() public virtual override {
        super.setUp();
    }

    function _createGuardian(bool allowSetGuard_) internal virtual override returns (SolvVaultGuardianBase) {
        return new SolvVaultGuardianForSafe14(safeAccount, _safeMultiSend, governor, allowSetGuard_);
    }

    function _createMultiSend() internal virtual override returns (address) {
        return address(new MultiSend());
    }

    function _createGnosisSafeProxyFactory() internal virtual override returns (address) {
        return address(new SafeProxyFactory());
    }

    function _createGnosisSafeSingleton() internal virtual override returns (address) {
        return address(new SafeL2());
    }

    function _createSafeProxy(address owner) internal virtual override returns (address) {
        address[] memory owners = new address[](1);
        owners[0] = owner;
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,
            1,
            address(0),
            new bytes(0),
            0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4,
            address(0),
            0,
            address(0)
        );

        vm.startPrank(owner);
        SafeProxy proxy =
            SafeProxyFactory(_safeProxyFactory).createProxyWithNonce(_safeSingleton, initializer, block.timestamp);
        vm.stopPrank();
        return address(proxy);
    }

    function _callExecTransaction(address contract_, uint256 value_, bytes memory data_) internal override {
        Enum.Operation operation_ = Enum.Operation.Call;
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        SafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _callExecTransactionShouldRevert(
        address contract_,
        uint256 value_,
        bytes memory data_,
        bytes memory revertMessage_
    ) internal virtual override {
        Enum.Operation operation_ = Enum.Operation.Call;
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        vm.expectRevert(revertMessage_);
        SafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _delegatecallExecTransaction(address contract_, uint256 value_, bytes memory data_) internal override {
        Enum.Operation operation_ = Enum.Operation.DelegateCall;
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        SafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _delegatecallExecTransactionShouldRevert(
        address contract_,
        uint256 value_,
        bytes memory data_,
        bytes memory revertMessage_
    ) internal virtual override {
        Enum.Operation operation_ = Enum.Operation.DelegateCall;
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        vm.expectRevert(revertMessage_);
        SafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _getSignature(address contract_, uint256 value_, bytes memory data_, Enum.Operation operation_)
        internal
        view
        returns (bytes memory)
    {
        uint256 nonce = SafeL2(safeAccount).nonce();
        bytes memory txHashData = SafeL2(safeAccount).encodeTransactionData(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), nonce
        );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privKeyForOwnerOfSafe, txHash);
        return bytes.concat(r, s, bytes1(v));
    }
}
