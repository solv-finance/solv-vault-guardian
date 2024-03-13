// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/common/SolvVaultGuardianBase.sol";

abstract contract SolvVaultGuardianTestBase is Test {

    address public constant OPEN_END_FUND_MARKET = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address public constant OPEN_END_FUND_SHARE = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    address public constant OPEN_END_FUND_REDEMPTION = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address public constant CEX_RECHARGE_ADDRESS = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address public constant WSOL = 0x2bcC6D6CdBbDC0a4071e48bb3B969b06B3330c07;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address internal _safeMultiSend;
    address internal _safeProxyFactory;
    address internal _safeSingleton;

    address payable public safeAccount;
    address public governor;
    address public ownerOfSafe;
    address public permissionlessAccount;
    uint256 internal _privKeyForOwnerOfSafe;

    function setUp() public virtual {
        _safeMultiSend = _createMultiSend();
        _safeProxyFactory = _createGnosisSafeProxyFactory();
        _safeSingleton = _createGnosisSafeSingleton();

        (ownerOfSafe, _privKeyForOwnerOfSafe) = makeAddrAndKey("OWNER_OF_SAFE");
        safeAccount = payable(_createSafeProxy(ownerOfSafe));

        governor = makeAddr("GOVERNOR");
        permissionlessAccount = makeAddr("PERMISSIONLESS_ACCOUNT");
    }

    function _createMultiSend() internal virtual returns (address);
    function _createGnosisSafeProxyFactory() internal virtual returns (address);
    function _createGnosisSafeSingleton() internal virtual returns (address);

    function _createSafeProxy(address owner) internal virtual returns (address);

    function _setSafeGuardShouldRevert(address guardian_, bytes memory revertMsg_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), guardian_);
        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(safeAccount, 0, data, revertMsg_);
        vm.stopPrank();
    }

    function _setSafeGuard(address guardian_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), guardian_);
        vm.startPrank(ownerOfSafe);
        _callExecTransaction(safeAccount, 0, data);
        vm.stopPrank();
    }

    function _setModule(address module_) internal virtual {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("enableModule(address)")), module_);
        vm.startPrank(ownerOfSafe);
        _callExecTransaction(safeAccount, 0, data);
        vm.stopPrank();
    }

    function _setModuleShouldRevert(address module_, bytes memory revertMsg_) internal virtual {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("enableModule(address)")), module_);
        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(safeAccount, 0, data, revertMsg_);

        vm.stopPrank();
    }

    function _erc20ApproveWithSafe(address token_, address spender_, uint256 amount_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), spender_, amount_);
        _callExecTransaction(token_, 0, data);
    }

    function _erc20ApproveWithSafeShouldRevert(
        address token_,
        address spender_,
        uint256 amount_,
        bytes memory revertMsg_
    ) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), spender_, amount_);
        _callExecTransactionShouldRevert(token_, 0, data, revertMsg_);
    }

    function _erc20TransferWithSafe(address token_, address to_, uint256 amount_) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to_, amount_);
        _callExecTransaction(token_, 0, data);
    }

    function _erc20TransferWithSafeShouldRevert(address token_, address to_, uint256 amount_, bytes memory revertMsg_)
        internal
    {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to_, amount_);
        _callExecTransactionShouldRevert(token_, 0, data, revertMsg_);
    }

    function _nativeTokenTransferWithSafe(address to_, uint256 amount_) internal {
        _callExecTransaction(to_, amount_, "");
    }

    function _nativeTokenTransferWithSafeShouldRevert(address to_, uint256 amount_, bytes memory revertMsg_) internal {
        _callExecTransactionShouldRevert(to_, amount_, "", revertMsg_);
    }

    function _callExecTransaction(
        address contract_, 
        uint256 value_, 
        bytes memory data_
    ) internal virtual;
    
    function _callExecTransactionShouldRevert(
        address contract_,
        uint256 value_,
        bytes memory data_,
        bytes memory revertMessage_
    ) internal virtual;
    
    function _delegatecallExecTransaction(
        address contract_, 
        uint256 value_, 
        bytes memory data_
    ) internal virtual;
    
    function _delegatecallExecTransactionShouldRevert(
        address contract_,
        uint256 value_,
        bytes memory data_,
        bytes memory revertMessage_
    ) internal virtual;
}
