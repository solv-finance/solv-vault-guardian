// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundMarket {
    struct SubscribeLimitInfo {
        uint256 hardCap;
        uint256 subscribeMin;
        uint256 subscribeMax;
        uint64 fundraisingStartTime;
        uint64 fundraisingEndTime;
    }

    struct InputPoolInfo {
        address openFundShare;
        address openFundRedemption;
        address currency;
        uint16 carryRate;
        address vault;
        uint64 valueDate;
        address carryCollector;
        address subscribeNavManager;
        address redeemNavManager;
        address navOracle;
        uint64 createTime;
        address[] whiteList;
        SubscribeLimitInfo subscribeLimitInfo;
    }

    struct PoolSFTInfo {
        address openFundShare;
        address openFundRedemption;
        uint256 openFundShareSlot;
        uint256 latestRedeemSlot;
    }

    struct PoolFeeInfo {
        uint16 carryRate;
        address carryCollector;
        uint64 latestProtocolFeeSettleTime;
    }

    struct ManagerInfo {
        address poolManager;
        address subscribeNavManager;
        address redeemNavManager;
    }

    struct PoolInfo {
        PoolSFTInfo poolSFTInfo;
        PoolFeeInfo poolFeeInfo;
        ManagerInfo managerInfo;
        SubscribeLimitInfo subscribeLimitInfo;
        address vault;
        address currency;
        address navOracle;
        uint64 valueDate;
        bool permissionless;
        uint256 fundraisingAmount;
    }

    function createPool(InputPoolInfo calldata inputPoolInfo_) external returns (bytes32 poolId_);
    function subscribe(bytes32 poolId_, uint256 currentAmount_, uint256 openFundShareId_, uint64 expireTime_)
        external
        returns (uint256 value_);

    function requestRedeem(bytes32 poolId_, uint256 openFundShareId_, uint256 openFundRedemptionId_, uint256 value_)
        external;
    function closeCurrentRedeemSlot(bytes32 poolId_) external;
    function setRedeemNav(bytes32 poolId_, uint256 redeemSlot_, uint256 nav_, uint256 currencyBalance_) external;
    function poolInfos(bytes32 poolId_) external returns (PoolInfo memory poolInfo_);
    function previousRedeemSlot(bytes32 poolId_) external returns (uint256 redeemSlot_);
}
