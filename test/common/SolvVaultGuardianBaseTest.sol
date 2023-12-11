// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/SolvVaultGuardian.sol";
import {GnosisSafeL2} from "safe-contracts/GnosisSafeL2.sol";

abstract contract SolvVaultGuardianBaseTest is Test {
    address public constant SAFE_MULTI_SEND_CONTRACT = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;

    address public constant OPEN_END_FUND_MARKET = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address public constant OPEN_END_FUND_SHARE = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    address public constant OPEN_END_FUND_REDEMPTION = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address public constant CEX_RECHARGE_ADDRESS = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address payable public safeAccount;
    address public governor;
    address public ownerOfSafe;
    address public permissionlessAccount;
    uint256 internal _privKeyForOwnerOfSafe;
    SolvVaultGuardian internal _guardian;

    function setUp() public virtual {
        safeAccount = payable(vm.envAddress("SAFE_ACCOUNT"));
        governor = vm.envAddress("GOVERNOR");
        ownerOfSafe = vm.envAddress("OWNER_OF_SAFE");
        permissionlessAccount = vm.envAddress("PERMISSIONLESS_ACCOUNT");
        _privKeyForOwnerOfSafe = vm.envUint("PRIVATE_KEY_FOR_OWNER_OF_SAFE");
    }

    function _setSafeGuard() internal {
        require(address(_guardian) != address(0), "SolvVaultGuardianBaseTest: guardian is not set");
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), _guardian);
        vm.startPrank(ownerOfSafe);
        _callExecTransaction(safeAccount, 0, data, Enum.Operation.Call);
        vm.stopPrank();
    }

    function _erc20Transfer(address token_, address to_, uint256 amount_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to_, amount_);
        _callExecTransaction(token_, 0, data, Enum.Operation.Call);
    }

    function _nativeTokenTransfer(address to_, uint256 amount_) internal {
        _callExecTransaction(to_, amount_, "", Enum.Operation.Call);
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

    function _callExecTransaction(address contract_, uint256 value_, bytes memory data_, Enum.Operation operation_)
        internal
    {
        bytes memory signature = _getSignature(contract_, value_, data_, operation_);
        GnosisSafeL2(safeAccount).execTransaction(
            contract_, value_, data_, operation_, 0, 0, 0, address(0), payable(address(0)), signature
        );
    }
}
