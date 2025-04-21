// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";

interface IERC20 {
    function decimals() external view returns (uint8);    
}

interface IOpenFundMarket {
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
    struct SubscribeLimitInfo {
        uint256 hardCap;
        uint256 subscribeMin;
        uint256 subscribeMax;
        uint64 fundraisingStartTime;
        uint64 fundraisingEndTime;
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

    function poolInfos(bytes32 poolId) external view returns (PoolInfo memory);
}

contract FoFNavManagerAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant NAME = "SolvVaultGuard_FoFNavManagerAuthorizationACL";
    uint256 public constant VERSION = 1;

    address public openFundMarket;

    EnumerableSet.Bytes32Set internal _authorizedPoolIds;

    constructor(address caller_, address openFundMarket_, bytes32[] memory authorizedPoolIds_)
        BaseACL(caller_)
    {
        openFundMarket = openFundMarket_;
        for (uint256 i = 0; i < authorizedPoolIds_.length; i++) {
            _authorizedPoolIds.add(authorizedPoolIds_[i]);
        }
    }

    function getAllAuthorizedPoolIds() public view returns (bytes32[] memory) {
        return _authorizedPoolIds.values();
    }

    function setSubscribeNav(bytes32 poolId_, uint256 /* time_ */, uint256 /** nav_ */) external view {
        require(_txn().value == 0, "FoFNavManagerAuthorizationACL: transaction value not allowed");
        require(_authorizedPoolIds.contains(poolId_), "FoFNavManagerAuthorizationACL: pool not authorized");
    }
    
    function setRedeemNav(bytes32 poolId_, uint256 /* redeemSlot_ */, uint256 nav_, uint256 currencyBalance_) external view {
        require(_txn().value == 0, "FoFNavManagerAuthorizationACL: transaction value not allowed");
        require(_authorizedPoolIds.contains(poolId_), "FoFNavManagerAuthorizationACL: pool not authorized");
        require(currencyBalance_ == 1, "FoFNavManagerAuthorizationACL: invalid currencyBalance");

        IOpenFundMarket.PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        uint8 decimals = IERC20(poolInfo.currency).decimals();
        require(nav_ == 10 ** decimals, "FoFNavManagerAuthorizationACL: invalid nav");
    }

}
