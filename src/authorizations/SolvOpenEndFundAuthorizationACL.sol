// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../common/BaseACL.sol";

interface IOpenFundRedemptionDelegate {
    function valueDecimals() external view returns (uint8);
    function concrete() external view returns (address concrete);
}

interface IOpenFundRedemptionConcrete {
    function getRedeemInfo(uint256 slot)
        external
        view
        returns (bytes32 poolId, address currency, uint256 createTime, uint256 nav);
    function slotTotalValue(uint256 slot) external view returns (uint256 totalValue);
    function slotCurrencyBalance(uint256 slot) external view returns (uint256 currencyBalance);
}

contract SolvOpenEndFundAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant NAME = "SolvVaultGuard_SolvOpenFundAuthorizationACL";
    uint256 public constant VERSION = 1;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public solvV3OpenEndFundRedemption;

    EnumerableSet.Bytes32Set internal _repayablePoolIds;

    event RepayablePoolIdAdded(bytes32 indexed repayablePoolId);
    event RepayablePoolIdRemoved(bytes32 indexed repayablePoolId);

    constructor(address caller_, address solvV3OpenEndFundRedemption_, bytes32[] memory repayablePoolIds_)
        BaseACL(caller_)
    {
        solvV3OpenEndFundRedemption = solvV3OpenEndFundRedemption_;
        for (uint256 i = 0; i < repayablePoolIds_.length; i++) {
            _repayablePoolIds.add(repayablePoolIds_[i]);
        }
    }

    function getAllRepayablePoolIds() public view returns (bytes32[] memory) {
        return _repayablePoolIds.values();
    }

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external view {
        uint256 transactionValue = _txn().value;
        if (currency_ == ETH) {
            require(transactionValue == repayCurrencyAmount_, "SolvV3RepayAuthorizer: transaction value too much");
        } else {
            require(transactionValue == 0, "SolvV3RepayAuthorizer: transaction value not allowed");
        }

        _checkRepayment(slot_, repayCurrencyAmount_);
    }

    function repayWithBalance(uint256 slot_, address, /* currency_ */ uint256 repayCurrencyAmount_) external view {
        require(_txn().value == 0, "SolvV3RepayAuthorizer: transaction value not allowed");
        _checkRepayment(slot_, repayCurrencyAmount_);
    }

    function _checkRepayment(uint256 slot, uint256 repayCurrencyAmount) internal view {
        address redemptionConcrete = IOpenFundRedemptionDelegate(solvV3OpenEndFundRedemption).concrete();
        (bytes32 poolId,,, uint256 redeemNav) = IOpenFundRedemptionConcrete(redemptionConcrete).getRedeemInfo(slot);
        require(_repayablePoolIds.contains(poolId), "SolvV3RepayAuthorizer: pool not repayable");

        uint256 slotTotalValue = IOpenFundRedemptionConcrete(redemptionConcrete).slotTotalValue(slot);
        uint256 slotCurrencyBalance = IOpenFundRedemptionConcrete(redemptionConcrete).slotCurrencyBalance(slot);
        uint8 decimals = IOpenFundRedemptionDelegate(solvV3OpenEndFundRedemption).valueDecimals();
        uint256 unpaidAmount = slotTotalValue * redeemNav / (10 ** decimals) - slotCurrencyBalance;
        require(repayCurrencyAmount <= unpaidAmount, "SolvV3RepayAuthorizer: over paid");
    }
}
