// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";

contract LendleAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuardian_AgniAuthorizationACL";
    uint256 public constant VERSION = 1;

    address public lendingPool;

    EnumerableSet.AddressSet internal _tokenWhitelist;

    event AddTokenWhitelist(address indexed token);

    constructor(
        address caller_,
        address safeAccount_,
        address lendingPool_,
        address[] memory tokenWhitelist_
    ) BaseACL(caller_) {
        safeAccount = safeAccount_;
        lendingPool = lendingPool_;
        for (uint256 i = 0; i < tokenWhitelist_.length; i++) {
            _addTokenWhitelist(tokenWhitelist_[i]);
        }
    }

    function _addTokenWhitelist(address token) internal {
        require(token != address(0), "LendleACL: token cannot be the zero address");
        if (_tokenWhitelist.add(token)) {
            emit AddTokenWhitelist(token);
        }
    }

    function checkToken(address token) public view virtual returns (bool) {
        return _tokenWhitelist.contains(token);
    }

    function deposit(address asset, uint256 /* amount */, address onBehalfOf, uint16 /* referralCode */) external view virtual {
        require(onBehalfOf == safeAccount, "LendleACL: onBehalfOf not allowed");
        require(checkToken(asset), "LendleACL: asset not allowed");
    }

    function withdraw(address asset, uint256 /* amount */, address to) external view virtual {
        require(to == safeAccount, "LendleACL: recipient not allowed");
        require(checkToken(asset), "LendleACL: asset not allowed");
    }

    function borrow(address asset, uint256 /* amount */, uint256 /* interestRateMode */, uint16 /* referralCode */, address onBehalfOf) external view virtual {
        require(onBehalfOf == safeAccount, "LendleACL: onBehalfOf not allowed");
        require(checkToken(asset), "LendleACL: asset not allowed");
    }

    function repay(address asset, uint256 /* amount */, uint256 /* rateMode */, address onBehalfOf) external view virtual {
        require(onBehalfOf == safeAccount, "LendleACL: onBehalfOf not allowed");
        require(checkToken(asset), "LendleACL: asset not allowed");
    }

    function swapBorrowRateMode(address asset, uint256 /* rateMode */) external view virtual {
        require(checkToken(asset), "LendleACL: asset not allowed");
    }

}
