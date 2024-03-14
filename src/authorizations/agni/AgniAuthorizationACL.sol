// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";
import {Path} from "../../libraries/Path.sol";

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

contract AgniAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Path for bytes;

    string public constant NAME = "SolvVaultGuardian_AgniAuthorizationACL";
    uint256 public constant VERSION = 1;

    address public agniSwapRouter;

    EnumerableSet.AddressSet internal _tokenWhitelist;

    event AddTokenWhitelist(address indexed token);

    constructor(
        address caller_,
        address safeAccount_,
        address agniSwapRouter_,
        address[] memory tokenWhitelist_
    ) BaseACL(caller_) {
        safeAccount = safeAccount_;
        agniSwapRouter = agniSwapRouter_;
        for (uint256 i = 0; i < tokenWhitelist_.length; i++) {
            _addTokenWhitelist(tokenWhitelist_[i]);
        }
    }

    function _addTokenWhitelist(address token) internal {
        require(token != address(0), "AgniACL: token cannot be the zero address");
        if (_tokenWhitelist.add(token)) {
            emit AddTokenWhitelist(token);
        }
    }

    function _checkToken(address token) internal view virtual returns (bool) {
        return _tokenWhitelist.contains(token);
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external view virtual {
        _checkValueZero();
        require(params.recipient == safeAccount, "AgniACL: recipient not allowed");
        require(_checkToken(params.tokenIn), "AgniACL: tokenIn not allowed");
        require(_checkToken(params.tokenOut), "AgniACL: tokenOut not allowed");
    }

    function exactInput(ExactInputParams calldata params) external view virtual {
        _checkValueZero();
        require(params.recipient == safeAccount, "AgniACL: recipient not allowed");

        bytes memory path = params.path;
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();
            (address tokenIn, address tokenOut,) = path.decodeFirstPool();
            require(_checkToken(tokenIn), "AgniACL: tokenIn not allowed");
            require(_checkToken(tokenOut), "AgniACL: tokenOut not allowed");
            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                break;
            }
        }
    }

}
