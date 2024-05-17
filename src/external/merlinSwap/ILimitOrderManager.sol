// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ILimitOrderManager {
    
    struct AddLimOrderParam {
        address tokenX;
        address tokenY;
        uint24 fee;
        int24 pt;
        uint128 amount;
        bool sellXEarnY;
        uint256 deadline;
    }
        
}