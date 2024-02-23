// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {Type} from "./Type.sol";
import {IBaseAuthorization} from "./IBaseAuthorization.sol";
import {Governable} from "../utils/Governable.sol";

abstract contract BaseAuthorization is IBaseAuthorization, Governable, IERC165 {
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

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBaseAuthorization).interfaceId;
    }

    function authorizationCheckTransaction(Type.TxData calldata txData_)
        external
        virtual
        onlyCaller
        returns (Type.CheckResult memory)
    {
        return _authorizationCheckTransaction(txData_);
    }

    function _authorizationCheckTransaction(Type.TxData calldata txData_)
        internal
        virtual
        returns (Type.CheckResult memory);
}
