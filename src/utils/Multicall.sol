// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Multicall {
	/**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);

        for (uint256 i; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                _revertWithParsedMessage(result);
            }

            results[i] = result;
        }

        return results;
    }

	  function _revertWithParsedMessage(bytes memory result) internal pure {
        (string memory revertMessage, bool hasRevertMessage) = _getRevertMessage(result);

        if (hasRevertMessage) {
            revert(revertMessage);
        } else {
            _revertWithCustomError(result);
        }
    }

    function _revertWithCustomError(bytes memory result) internal pure {
        // referenced from https://ethereum.stackexchange.com/a/123588
        uint256 length = result.length;
        assembly {
            revert(add(result, 0x20), length)
        }
    }

	 // To get the revert reason, referenced from https://ethereum.stackexchange.com/a/83577
    function _getRevertMessage(bytes memory result) internal pure returns (string memory, bool) {
        // If the result length is less than 68, then the transaction either panicked or failed silently
        if (result.length < 68) {
            return ("", false);
        }

        bytes4 errorSelector = _getErrorSelectorFromData(result);

        // 0x08c379a0 is the selector for Error(string)
        // referenced from https://blog.soliditylang.org/2021/04/21/custom-errors/
        if (errorSelector == bytes4(0x08c379a0)) {
            assembly {
                result := add(result, 0x04)
            }

            return (abi.decode(result, (string)), true);
        }

        // error may be a custom error, return an empty string for this case
        return ("", false);
    }


    function _getErrorSelectorFromData(bytes memory data) internal pure returns (bytes4) {
        bytes4 errorSelector;

        assembly {
            errorSelector := mload(add(data, 0x20))
        }

        return errorSelector;
    }

}