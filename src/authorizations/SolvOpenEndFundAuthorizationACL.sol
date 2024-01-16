// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../common/BaseACL.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
}

interface ISFTDelegate {
    function valueDecimals() external view returns (uint8);
    function concrete() external view returns (address);
    function contractType() external view returns (string memory);
}

interface IOpenFundShareConcrete {
    function slotBaseInfo(uint256 slot) external view returns (
        address issuer, address currency, uint64 valueDate, uint64 maturity, 
        uint64 createTime, bool transferable, bool isValid
    );
    function slotExtInfo(uint256 slot) external view returns (
        address supervisor, uint256 issueQuota, uint8 interestType, 
        int32 interestRate, bool isInterestRateSet, string memory externalURI
    );
    function slotTotalValue(uint256 slot) external view returns (uint256);
    function slotCurrencyBalance(uint256 slot) external view returns (uint256);
}

interface IOpenFundRedemptionConcrete {
    function getRedeemInfo(uint256 slot) external view returns (bytes32 poolId, address currency, uint256 createTime, uint256 nav);
    function slotTotalValue(uint256 slot) external view returns (uint256);
    function slotCurrencyBalance(uint256 slot) external view returns (uint256);
}

contract SolvOpenEndFundAuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    string public constant NAME = "SolvVaultGuard_SolvOpenFundAuthorizationACL";
    uint256 public constant VERSION = 1;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal FULL_PERCENTAGE = 1e4;
    uint256 internal REPAY_RATE_SCALAR = 1e8;

    address public solvV3OpenEndFundRedemption;

    EnumerableSet.Bytes32Set internal _repayablePoolIds;

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
            require(transactionValue == repayCurrencyAmount_, "SolvOpenEndFundAuthorizationACL: transaction value too much");
        } else {
            require(transactionValue == 0, "SolvOpenEndFundAuthorizationACL: transaction value not allowed");
        }

        _checkRepayment(slot_, repayCurrencyAmount_);
    }

    function repayWithBalance(uint256 slot_, address, /* currency_ */ uint256 repayCurrencyAmount_) external view {
        require(_txn().value == 0, "SolvOpenEndFundAuthorizationACL: transaction value not allowed");
        _checkRepayment(slot_, repayCurrencyAmount_);
    }

    function _checkRepayment(uint256 slot, uint256 repayCurrencyAmount) internal view {
        string memory contractType = ISFTDelegate(solvV3OpenEndFundRedemption).contractType();
        address concrete = ISFTDelegate(solvV3OpenEndFundRedemption).concrete();

        if (keccak256(abi.encodePacked(contractType)) == keccak256(abi.encodePacked("Open Fund Shares"))) {
            require(repayCurrencyAmount <= _shareUnpaidAmount(concrete, slot), "SolvOpenEndFundAuthorizationACL: share over paid");

        } else if (keccak256(abi.encodePacked(contractType)) == keccak256(abi.encodePacked("Open Fund Redemptions"))) {
            require(repayCurrencyAmount <= _redemptionUnpaidAmount(concrete, slot), "SolvOpenEndFundAuthorizationACL: redemption over paid");

        } else {
            revert("SolvOpenEndFundAuthorizationACL: invalid contract type");
        }
    }

    function _shareUnpaidAmount(address concrete, uint256 slot) internal view virtual returns (uint256) {
        (, address currency, uint64 valueDate, uint64 maturity,,,) = IOpenFundShareConcrete(concrete).slotBaseInfo(slot);
        (,,, int32 interestRate, bool isInterestRateSet,) = IOpenFundShareConcrete(concrete).slotExtInfo(slot);
        require(isInterestRateSet, "SolvOpenEndFundAuthorizationACL: interest rate not set");

        uint256 scaledFullPercentage = FULL_PERCENTAGE * REPAY_RATE_SCALAR;
        uint256 scaledPositiveInterestRate = 
            (interestRate < 0 ? uint256(int256(0 - interestRate)) : uint256(int256(interestRate))) * 
            REPAY_RATE_SCALAR * (maturity - valueDate) / (360 * 24 * 60 * 60);
        uint256 repayRate = interestRate < 0 ? scaledFullPercentage - scaledPositiveInterestRate : 
            scaledFullPercentage + scaledPositiveInterestRate;

        uint8 currencyDecimals = currency == ETH ? 18 : IERC20(currency).decimals();
        uint8 shareDecimals = ISFTDelegate(solvV3OpenEndFundRedemption).valueDecimals();

        uint256 slotTotalValue = IOpenFundShareConcrete(concrete).slotTotalValue(slot);
        uint256 slotCurrencyBalance = IOpenFundShareConcrete(concrete).slotCurrencyBalance(slot);
        uint256 payableAmount = slotTotalValue * repayRate * (10 ** currencyDecimals) / FULL_PERCENTAGE / REPAY_RATE_SCALAR / (10 ** shareDecimals);
        return payableAmount - slotCurrencyBalance;
    }

    function _redemptionUnpaidAmount(address concrete, uint256 slot) internal view virtual returns (uint256) {
        (bytes32 poolId,,, uint256 redeemNav) = IOpenFundRedemptionConcrete(concrete).getRedeemInfo(slot);
        require(_repayablePoolIds.contains(poolId), "SolvOpenEndFundAuthorizationACL: pool not repayable");

        uint256 slotTotalValue = IOpenFundRedemptionConcrete(concrete).slotTotalValue(slot);
        uint256 slotCurrencyBalance = IOpenFundRedemptionConcrete(concrete).slotCurrencyBalance(slot);
        uint8 decimals = ISFTDelegate(solvV3OpenEndFundRedemption).valueDecimals();
        return slotTotalValue * redeemNav / (10 ** decimals) - slotCurrencyBalance;
    }

}
