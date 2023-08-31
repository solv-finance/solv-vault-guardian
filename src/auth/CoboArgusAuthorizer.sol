// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {BaseAuthorizer} from "../common/BaseAuthorizer.sol";
import {TxData} from "../common/Types.sol";

contract CoboArgusAuthorizer is BaseAuthorizer {
    function _checkTransaction(
        TxData calldata txData
    ) internal view virtual override returns (bool) {
		return false;
	}
}