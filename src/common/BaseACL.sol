// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {Type} from "./Type.sol";
import {IBaseACL} from "./IBaseACL.sol";

abstract contract BaseACL is IBaseACL, IERC165 {
    address public caller;
    address public safeAccount;
    address public solvGuard;

    fallback() external {}

    constructor(address caller_) {
        caller = caller_;
    }

    modifier onlyCaller() virtual {
        require(msg.sender == caller, "onlyCaller");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBaseACL).interfaceId;
    }

    function preCheck(address from_, address to_, bytes calldata data_, uint256 value_)
        external
        virtual
        onlyCaller
        returns (Type.CheckResult memory result_)
    {
        result_ = _preCheck(from_, to_, data_, value_);
    }

    function _preCheck(address from_, address to_, bytes calldata data_, uint256 value_)
        internal
        virtual
        returns (Type.CheckResult memory result_)
    {
        (bool success, bytes memory revertData) =
            address(this).staticcall(_packTxn(Type.TxData(from_, to_, value_, data_)));
        result_ = _parseReturnData(success, revertData);
    }

    function _parseReturnData(bool success, bytes memory revertData)
        internal
        pure
        returns (Type.CheckResult memory result_)
    {
        if (success) {
            // ACL checking functions should not return any bytes which differs from normal view functions.
            require(revertData.length == 0, "ACL Function return non empty");
            result_.success = true;
        } else {
            if (revertData.length < 68) {
                // 8(bool) + 32(length)
                result_.message = string(revertData);
            } else {
                assembly {
                    // Slice the sighash.
                    revertData := add(revertData, 0x04)
                }
                result_.message = abi.decode(revertData, (string));
            }
        }
    }

    function _packTxn(Type.TxData memory txData_) internal pure virtual returns (bytes memory) {
        bytes memory txnData = abi.encode(txData_);
        bytes memory callDataSize = abi.encode(txData_.data.length);
        return abi.encodePacked(txData_.data, txnData, callDataSize);
    }

    function _unpackTxn() internal view virtual returns (Type.TxData memory txData_) {
        uint256 end = msg.data.length;
        uint256 callDataSize = abi.decode(msg.data[end - 32:end], (uint256));
        txData_ = abi.decode(msg.data[callDataSize:], (Type.TxData));
    }

    function _txn() internal view virtual returns (Type.TxData memory) {
        return _unpackTxn();
    }

    function _checkValueZero() internal view virtual {
        require(_txn().value == 0, "Value not zero");
    }
}
