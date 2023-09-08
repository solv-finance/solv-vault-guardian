// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/common/SolvSafeguardRootGuard.sol";

abstract contract SafeguardBaseTest is Test {
    address payable public constant SAFE_ACCOUNT = payable(0x01c106FadEbBB2D32c2EAcAB3F5874B25B009cbb);
    address public constant SAFE_MULTI_SEND_CONTRACT = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
	address public constant OPEN_END_FUND_MARKET = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
	address public constant OPEN_END_FUND_SHARE = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
	address public constant OPEN_END_FUND_REDEMPTION = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
	address public constant CEX_RECHARGE_ADDRESS = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address internal _msgSender;
    uint256 internal _privKey;
    SolvSafeguardRootGuard internal _safeguard;

    function setUp() virtual public {
        _privKey = vm.envUint("PRIVATE_KEY");
        _msgSender = vm.addr(_privKey);
    }

    function _setSafeGuard(address guard_) internal {
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("setGuard(address)")),
            guard_
        );
        vm.startPrank(_msgSender);
        _callExecTransaction(SAFE_ACCOUNT, data, Enum.Operation.Call);
        vm.stopPrank();
    }

    function _erc20Transfer(address token_, address to_, uint256 amount_) internal {
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("transfer(address,uint256)")),
            to_,
            amount_
        );
        _callExecTransaction(token_, data, Enum.Operation.Call);
    }

    function _getSignature(
        address contract_,
        bytes memory data_,
        Enum.Operation operation_
    ) internal view returns (bytes memory) {
        uint256 nonce = GnosisSafeL2(SAFE_ACCOUNT).nonce();
        bytes memory txHashData = GnosisSafeL2(SAFE_ACCOUNT)
            .encodeTransactionData(
                contract_,
                0,
                data_,
                operation_,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                nonce
            );
        bytes32 txHash = keccak256(txHashData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privKey, txHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function _callExecTransaction(
        address contract_,
        bytes memory data_,
        Enum.Operation operation_
    ) internal {
        bytes memory signature = _getSignature(contract_, data_, operation_);
        GnosisSafeL2(SAFE_ACCOUNT).execTransaction(
            contract_,
            0,
            data_,
            operation_,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signature
        );
    }
}
