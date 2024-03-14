// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Type} from "./Type.sol";

interface IBaseAuthorization {
    function authorizationCheckTransaction(Type.TxData calldata txData_) external returns (Type.CheckResult memory);
}
