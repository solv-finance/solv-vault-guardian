// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";
import {Path} from "../../libraries/Path.sol";
import {BytesLib} from "../../libraries/BytesLib.sol";
import "../../external/merlinSwap/ISwap.sol";

contract MerlinSwapAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Path for bytes;
    using BytesLib for bytes;

    string public constant NAME = "SolvVaultGuardian_MerlinSwapAuthorizationACL";
    uint256 public constant VERSION = 1;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;
    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    address public merlinSwap;

    EnumerableSet.AddressSet internal _tokenWhitelist;

    event AddTokenWhitelist(address indexed token);

    constructor(
        address caller_,
        address safeAccount_,
        address merlinSwap_,
        address[] memory tokenWhitelist_
    ) BaseACL(caller_) {
        safeAccount = safeAccount_;
        merlinSwap = merlinSwap_;
        for (uint256 i = 0; i < tokenWhitelist_.length; i++) {
            _addTokenWhitelist(tokenWhitelist_[i]);
        }
    }

    function _addTokenWhitelist(address token) internal {
        require(token != address(0), "MerlinSwapACL: token cannot be the zero address");
        if (_tokenWhitelist.add(token)) {
            emit AddTokenWhitelist(token);
        }
    }

    function _checkToken(address token) internal view virtual returns (bool) {
        return _tokenWhitelist.contains(token);
    }

    function _checkPath(bytes memory path) internal view {
        uint256 start = 0;
        while (start < path.length) {
            address token = path.toAddress(start);
            require(_checkToken(token), "MerlinSwapACL: token not allowed");
            start = start + NEXT_OFFSET;
        }
    }

    function swapDesire(ISwap.SwapDesireParams calldata params) external view virtual {
        require(params.recipient == safeAccount, "MerlinSwapACL: recipient not allowed");
        _checkPath(params.path);
    }

    function swapAmount(ISwap.SwapAmountParams calldata params) external view virtual {
        require(params.recipient == safeAccount, "MerlinSwapACL: recipient not allowed");
        _checkPath(params.path);
    }

    function swapY2X(ISwap.SwapParams calldata swapParams) external view virtual {
        require(_checkToken(swapParams.tokenX), "MerlinSwapACL: tokenX not allowed");
        require(_checkToken(swapParams.tokenY), "MerlinSwapACL: tokenY not allowed");
        require(swapParams.recipient == safeAccount, "MerlinSwapACL: recipient not allowed");
    }

    function swapY2XDesireX(ISwap.SwapParams calldata swapParams) external view virtual {
        require(_checkToken(swapParams.tokenX), "MerlinSwapACL: tokenX not allowed");
        require(_checkToken(swapParams.tokenY), "MerlinSwapACL: tokenY not allowed");
        require(swapParams.recipient == safeAccount, "MerlinSwapACL: recipient not allowed");
    }

    function swapX2Y(ISwap.SwapParams calldata swapParams) external view virtual {
        require(_checkToken(swapParams.tokenX), "MerlinSwapACL: tokenX not allowed");
        require(_checkToken(swapParams.tokenY), "MerlinSwapACL: tokenY not allowed");
        require(swapParams.recipient == safeAccount, "MerlinSwapACL: recipient not allowed");
    }

    function swapX2YDesireY(ISwap.SwapParams calldata swapParams) external view virtual {
        require(_checkToken(swapParams.tokenX), "MerlinSwapACL: tokenX not allowed");
        require(_checkToken(swapParams.tokenY), "MerlinSwapACL: tokenY not allowed");
        require(swapParams.recipient == safeAccount, "MerlinSwapACL: recipient not allowed");
    }

}
