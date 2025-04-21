// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/SolvVaultGuardianForSafe13.sol";
import {GnosisSafeL2} from "safe-contracts-1.3.0/GnosisSafeL2.sol";

contract Avax_SolvBTC_Nav is Test {

    address payable internal safeAccount = payable(0x538dB8BDD683b941d6Cee61d9a7a128D53c32522);
    address internal safeOwner;
    uint256 internal safeOwnerPrivKey;
    address internal guardian = 0x82fb74b8A26726226ACF8aAcC63A06017A247Eb6;

    address internal openFundMarket = 0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf;
    bytes32 internal poolId = 0xf5ae38da3319d22b4628e635f6fa60bf966de13c5334b6845eba764d6321e16b;
    bytes32 internal fakePoolId = 0xf5ae38da3319d22b4628e635f6fa60bf966de13c5334b6845eba764d6321e16c;

    function setUp() public virtual {
        (safeOwner, safeOwnerPrivKey) = makeAddrAndKey("SAFE_OWNER");
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

    function test_SetSubscribeNavAfterSettingGuard() public {
        _setGuard();
        vm.startPrank(safeOwner);
        _callExecTransaction(openFundMarket, 0, abi.encodeWithSignature("setSubscribeNav(bytes32,uint256,uint256)", poolId, block.timestamp, 1e8));
        _callExecTransactionShouldRevert(
            openFundMarket, 0.1 ether, abi.encodeWithSignature("setSubscribeNav(bytes32,uint256,uint256)", poolId, block.timestamp, 1e8), 
            "FoFNavManagerAuthorizationACL: transaction value not allowed"
        );
        _callExecTransactionShouldRevert(
            openFundMarket, 0, abi.encodeWithSignature("setSubscribeNav(bytes32,uint256,uint256)", fakePoolId, block.timestamp, 1e8), 
            "FoFNavManagerAuthorizationACL: pool not authorized"
        );
        vm.stopPrank();
    }

    function test_SetRedeemNavAfterSettingGuard() public {
        _setGuard();
        vm.startPrank(safeOwner);
        _callExecTransactionShouldRevert(
            openFundMarket, 0.1 ether, abi.encodeWithSignature("setRedeemNav(bytes32,uint256,uint256,uint256)", poolId, 111, 1e8, 1),
            "FoFNavManagerAuthorizationACL: transaction value not allowed"
        );
        _callExecTransactionShouldRevert(
            openFundMarket, 0 ether, abi.encodeWithSignature("setRedeemNav(bytes32,uint256,uint256,uint256)", fakePoolId, 111, 1e8, 1),
            "FoFNavManagerAuthorizationACL: pool not authorized"
        );
        _callExecTransactionShouldRevert(
            openFundMarket, 0 ether, abi.encodeWithSignature("setRedeemNav(bytes32,uint256,uint256,uint256)", poolId, 111, 1.01e8, 1),
            "FoFNavManagerAuthorizationACL: invalid nav"
        );
        _callExecTransactionShouldRevert(
            openFundMarket, 0 ether, abi.encodeWithSignature("setRedeemNav(bytes32,uint256,uint256,uint256)", poolId, 111, 1e8, 10),
            "FoFNavManagerAuthorizationACL: invalid currencyBalance"
        );
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