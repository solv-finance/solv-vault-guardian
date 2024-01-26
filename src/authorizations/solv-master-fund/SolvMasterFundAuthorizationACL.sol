// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";
import {Governable} from "../../utils/Governable.sol";
import {IERC3525} from "../../external/IERC3525.sol";
import {IOpenFundMarket} from "../../external/IOpenFundMarket.sol";

contract SolvMasterFundAuthorizationACL is BaseACL, Governable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant NAME = "SolvVaultGuardian_MasterFundAuthorizationACL";
    uint256 public constant VERSION = 1;

    address internal _openFundMarket;

    EnumerableSet.Bytes32Set internal _poolIdWhitelist;

    event AddPoolIdWhitelist(bytes32 indexed poolId);
    event RemovePoolIdWhitelist(bytes32 indexed poolId);

    constructor(
        address caller_,
        address safeAccount_,
        address governor_,
        address openFundMarket_,
        bytes32[] memory poolIdWhitelist_
    ) BaseACL(caller_) Governable(governor_) {
        safeAccount = safeAccount_;
        _openFundMarket = openFundMarket_;
        for (uint256 i = 0; i < poolIdWhitelist_.length; i++) {
            _addPoolIdWhitelist(poolIdWhitelist_[i]);
        }
    }

    function addPoolIdWhitelist(bytes32[] calldata poolIdWhitelist_) external virtual onlyGovernor {
        for (uint256 i = 0; i < poolIdWhitelist_.length; i++) {
            _addPoolIdWhitelist(poolIdWhitelist_[i]);
        }
    }

    function removePoolIdWhitelist(bytes32[] calldata poolIdWhitelist_) external virtual onlyGovernor {
        for (uint256 i = 0; i < poolIdWhitelist_.length; i++) {
            _removePoolIdWhitelist(poolIdWhitelist_[i]);
        }
    }

    function _addPoolIdWhitelist(bytes32 poolId) internal virtual {
        if (_poolIdWhitelist.add(poolId)) {
            emit AddPoolIdWhitelist(poolId);
        }
    }

    function _removePoolIdWhitelist(bytes32 poolId) internal virtual {
        if (_poolIdWhitelist.remove(poolId)) {
            emit RemovePoolIdWhitelist(poolId);
        }
    }

    function getPoolIdWhitelist() external view virtual returns (bytes32[] memory) {
        return _poolIdWhitelist.values();
    }

    function checkPoolId(bytes32 poolId) public view virtual returns (bool) {
        return _poolIdWhitelist.contains(poolId);
    }

    function subscribe(bytes32 poolId, uint256 /* currencyAmount */, uint256 openFundShareId, uint64 /* expireTime */) 
        external 
        view 
        virtual 
    {
        require(checkPoolId(poolId), "MasterFundACL: pool not allowed");
        if (openFundShareId != 0) {
            IOpenFundMarket.PoolInfo memory poolInfo = IOpenFundMarket(_openFundMarket).poolInfos(poolId);
            IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
            require(safeAccount == openFundShare.ownerOf(openFundShareId), "MasterFundACL: invalid share receiver");
        }
    }

    function requestRedeem(bytes32 poolId, uint256 /* openFundShareId */, uint256 openFundRedemptionId, uint256 /* redeemValue */)
        external
        view
        virtual
    {
        require(checkPoolId(poolId), "MasterFundACL: pool not allowed");
        if (openFundRedemptionId != 0) {
            IOpenFundMarket.PoolInfo memory poolInfo = IOpenFundMarket(_openFundMarket).poolInfos(poolId);
            IERC3525 openFundRedemption = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
            require(safeAccount == openFundRedemption.ownerOf(openFundRedemptionId), "MasterFundACL: invalid redemption receiver");
        }
    }

}
