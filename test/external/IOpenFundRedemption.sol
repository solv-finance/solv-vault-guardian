// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundRedemption {
    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
}
