// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Type} from "./Type.sol";

interface IBaseACL {
    function preCheck(address from_, address to_, bytes calldata data_, uint256 value_)
        external
        returns (Type.CheckResult memory result_);
}
