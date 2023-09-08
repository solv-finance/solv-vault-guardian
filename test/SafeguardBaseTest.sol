// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SolvSafeguard.sol";

abstract contract SafeguardBaseTest is Test {
    address payable public constant safeAccount =
    payable(0x01c106FadEbBB2D32c2EAcAB3F5874B25B009cbb);
    address internal _msgSender;
    uint256 internal _privKey;
    SolvSafeguard internal _safeguard;

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
        _callExecTransaction(safeAccount, data);
        vm.stopPrank();
    }

    function _getSignature(
        address contract_,
        bytes memory data_
    ) internal view returns (bytes memory) {
        uint256 nonce = GnosisSafeL2(safeAccount).nonce();
        bytes memory txHashData = GnosisSafeL2(safeAccount)
            .encodeTransactionData(
                contract_,
                0,
                data_,
                Enum.Operation.Call,
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
        bytes memory data_
    ) internal {
        bytes memory signature = _getSignature(contract_, data_);
        GnosisSafeL2(safeAccount).execTransaction(
            contract_,
            0,
            data_,
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signature
        );
    }
}
