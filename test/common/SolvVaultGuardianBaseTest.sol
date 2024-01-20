// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/SolvVaultGuardianForSafe13.sol";
import {GnosisSafeL2} from "safe-contracts-1.3.0/GnosisSafeL2.sol";

abstract contract SolvVaultGuardianBaseTest is Test {
    address public constant SAFE_MULTI_SEND_CONTRACT = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;

    address public constant OPEN_END_FUND_MARKET = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address public constant OPEN_END_FUND_SHARE = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    address public constant OPEN_END_FUND_REDEMPTION = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address public constant CEX_RECHARGE_ADDRESS = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address payable public safeAccount;
    address public governor;
    address public ownerOfSafe;
    address public permissionlessAccount;
    uint256 internal _privKeyForOwnerOfSafe;
    SolvVaultGuardianForSafe13 internal _guardian;

    bytes internal _revertMessage;

    function setUp() public virtual {
        safeAccount = payable(vm.envAddress("SAFE_ACCOUNT"));
        governor = vm.envAddress("GOVERNOR");
        ownerOfSafe = vm.envAddress("OWNER_OF_SAFE");
        permissionlessAccount = vm.envAddress("PERMISSIONLESS_ACCOUNT");
        _privKeyForOwnerOfSafe = vm.envUint("PRIVATE_KEY_FOR_OWNER_OF_SAFE");
    }

    function _setSafeGuard() internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), _guardian);
        vm.startPrank(ownerOfSafe);
        _callExecTransaction(safeAccount, 0, data, Enum.Operation.Call);
        vm.stopPrank();
    }

    function _erc20ApproveWithSafe(address token_, address spender_, uint256 amount_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), spender_, amount_);
        _callExecTransaction(token_, 0, data, Enum.Operation.Call);
    }

    function _erc20TransferWithSafe(address token_, address to_, uint256 amount_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to_, amount_);
        _callExecTransaction(token_, 0, data, Enum.Operation.Call);
    }

    function _nativeTokenTransferWithSafe(address to_, uint256 amount_) internal {
        _callExecTransaction(to_, amount_, "", Enum.Operation.Call);
    }

    function _callExecTransaction(address contract_, uint256 value_, bytes memory data_, Enum.Operation operation_)
        internal
    {
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        if (_revertMessage.length > 0) {
            vm.expectRevert(_revertMessage);
        }
        GnosisSafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }

    function _checkFromGuardian(address contract_, uint256 value_, bytes memory data_, Enum.Operation operation_)
        internal
    {
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        if (_revertMessage.length > 0) {
            vm.expectRevert(_revertMessage);
        }
        _guardian.checkTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature, ownerOfSafe
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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privKeyForOwnerOfSafe, txHash);
        return bytes.concat(r, s, bytes1(v));
    }
}
