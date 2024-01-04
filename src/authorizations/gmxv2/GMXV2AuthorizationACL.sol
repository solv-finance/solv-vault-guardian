// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";

struct CreateDepositParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minMarketTokens;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
}

struct CreateWithdrawalParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
}

contract GMXV2AuthorizationACL is BaseACL {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "SolvVaultGuard_GMXV2AuthorizationACL";
    uint256 public constant VERSION = 1;

    struct CollateralPair {
        address longCollateral;
        address shortCollateral;
    }

    mapping(address => CollateralPair) public authorizedPools;
    address public exchangeRouter;
    address public depositVault;
    address public withdrawalVault;

    event AddGmxPool(address indexed gmToken, CollateralPair collateralPair);

    constructor(
        address caller_,
        address safeAccount_,
        address exchangeRouter_,
        address depositVault_,
        address withdrawalVault_,
        address[] memory gmTokens_,
        CollateralPair[] memory collateralPairs_
    ) BaseACL(caller_) {
        safeAccount = safeAccount_;
        exchangeRouter = exchangeRouter_;
        depositVault = depositVault_;
        withdrawalVault = withdrawalVault_;

        require(gmTokens_.length == collateralPairs_.length, "array length not matches");
        for (uint256 i = 0; i < gmTokens_.length; i++) {
            _addGmxPool(gmTokens_[i], collateralPairs_[i]);
        }
    }

    function _addGmxPool(address gmToken_, CollateralPair memory collateralPair_) internal {
        require(
            gmToken_ != address(0) && collateralPair_.longCollateral != address(0)
                && collateralPair_.shortCollateral != address(0),
            "invalid token addresses"
        );
        authorizedPools[gmToken_] = collateralPair_;
        emit AddGmxPool(gmToken_, collateralPair_);
    }

    function isPoolAuthorized(address gmToken_) public view returns (bool) {
        return authorizedPools[gmToken_].longCollateral != address(0);
    }

    function multicall(bytes[] calldata data) external view {
        require(data.length == 2 || data.length == 3, "invalid data length");
        uint256 value = _txn().value;
        bytes4 operation = bytes4(data[data.length - 1]);

        if (operation == this.createDeposit.selector) {
            (CreateDepositParams memory depositParams) = abi.decode(data[data.length - 1][4:], (CreateDepositParams));
            createDeposit(depositParams);

            // for deposit operations, the first call should be `sendWnt` and the receiver should be GmxDepositVault
            require(bytes4(data[0]) == this.sendWnt.selector, "sendWnt error");
            (address wntReceiver, uint256 amount) = abi.decode(data[0][4:], (address, uint256));
            require(wntReceiver == depositVault, "invalid wnt receiver");
            require(amount == value, "invalid wnt amount");

            // for deposit operations with non-ETH tokens, the second call should be `sendTokens`
            if (data.length == 3) {
                require(bytes4(data[1]) == this.sendTokens.selector, "sendTokens error");
                (address token, address tokenReceiver,) = abi.decode(data[1][4:], (address, address, uint256));
                CollateralPair memory collateralPair = authorizedPools[depositParams.market];
                require(
                    token == collateralPair.longCollateral || token == collateralPair.shortCollateral,
                    "token not authorized"
                );
                require(tokenReceiver == depositVault, "invalid token receiver");
            }
        } else if (operation == this.createWithdrawal.selector) {
            (CreateWithdrawalParams memory withdrawalParams) =
                abi.decode(data[data.length - 1][4:], (CreateWithdrawalParams));
            createWithdrawal(withdrawalParams);

            // for withdrawal operations, the first call should be `sendWnt` and the receiver should be GmxWithdrawalVault
            require(bytes4(data[0]) == this.sendWnt.selector, "sendWnt error");
            (address wntReceiver, uint256 amount) = abi.decode(data[0][4:], (address, uint256));
            require(wntReceiver == withdrawalVault, "invalid wnt receiver");
            require(amount == value, "invalid wnt amount");

            // for withdrawal operations, the second call should be `sendTokens` and the receiver should be GmxWithdrawalVault
            require(bytes4(data[1]) == this.sendTokens.selector, "sendTokens error");
            (address token, address tokenReceiver,) = abi.decode(data[1][4:], (address, address, uint256));
            require(token == withdrawalParams.market, "GM token not matches");
            require(tokenReceiver == withdrawalVault, "invalid token receiver");
        } else {
            revert("not deposit or withdraw operation");
        }
    }

    function sendWnt(address, /* receiver */ uint256 /* amount */ ) external pure {
        revert("sendWnt not allowed");
    }

    function sendTokens(address, /* token */ address, /* receiver */ uint256 /* amount */ ) external pure {
        revert("sendTokens not allowed");
    }

    function createDeposit(CreateDepositParams memory depositParams) public view {
        require(isPoolAuthorized(depositParams.market), "pool not authorized");
        require(depositParams.receiver == safeAccount, "invalid deposit receiver");
        require(depositParams.callbackContract == address(0), "deposit callback not allowed");
    }

    function createWithdrawal(CreateWithdrawalParams memory withdrawalParams) public view {
        require(isPoolAuthorized(withdrawalParams.market), "pool not authorized");
        require(withdrawalParams.receiver == safeAccount, "invalid withdrawal receiver");
        require(withdrawalParams.callbackContract == address(0), "withdrawal callback not allowed");
    }
}
