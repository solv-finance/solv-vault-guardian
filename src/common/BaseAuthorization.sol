// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Type} from "./Type.sol";
import {Governable} from "../utils/Governable.sol";

abstract contract BaseAuthorization is Governable {
    address public caller;

    modifier onlyCaller() {
        if (msg.sender != caller) {
            revert("BaseAuthorization: onlySelf");
        }
        _;
    }

    constructor(address caller_, address governor_) Governable(governor_) {
        caller = caller_;
    }

    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    function guardCheckTransaction(Type.TxData calldata txData_)
        external
        virtual
        onlyCaller
        returns (Type.CheckResult memory)
    {
        return _guardCheckTransaction(txData_);
    }

    function _guardCheckTransaction(Type.TxData calldata txData_) internal virtual returns (Type.CheckResult memory);
}
