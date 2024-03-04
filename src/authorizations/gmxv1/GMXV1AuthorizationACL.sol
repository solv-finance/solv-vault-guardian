// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";

contract GMXV1AuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuard_GMXV1AuthorizationACL";
    uint256 public constant VERSION = 1;

    address public constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    EnumerableSet.AddressSet internal _allowTokens;

    constructor(address caller_, address safeAccount_, address[] memory tokens_) BaseACL(caller_) {
        for (uint256 i = 0; i < tokens_.length; i++) {
            _allowTokens.add(tokens_[i]);
        }
        safeAccount = safeAccount_;
    }

    function mintAndStakeGlp(address _token, uint256, /*_amount*/ uint256, /*_minUsdg*/ uint256 /*_minGlp*/ )
        external
        view
    {
        require(_allowTokens.contains(_token), "GMXV1ACL: token not allowed");
    }

    function unstakeAndRedeemGlp(address _tokenOut, uint256, /*_glpAmount*/ uint256, /*_minOut*/ address _receiver)
        external
        view
    {
        require(_allowTokens.contains(_tokenOut), "GMXV1ACL: token not allowed");
        require(_receiver == safeAccount, "GMXV1ACL: receiver not safeAccount");
    }

    function mintAndStakeGlpETH(uint256, /*_minUsdg*/ uint256 /*_minGlp*/ ) external view {
        require(_allowTokens.contains(NATIVE_ETH), "GMXV1ACL: token not allowed");
    }

    function unstakeAndRedeemGlpETH(uint256, /*_glpAmount*/ uint256, /*_minOut*/ address payable _receiver)
        external
        view
    {
        require(_allowTokens.contains(NATIVE_ETH), "GMXV1ACL: token not allowed");
        require(_receiver == safeAccount, "GMXV1ACL: receiver not safeAccount");
    }
}
