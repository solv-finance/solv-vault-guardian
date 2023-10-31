// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/console.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {BaseACL} from "../../common/BaseACL.sol";
import {BaseGuard} from "../../common/BaseGuard.sol";

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

contract GMXV2ACL is BaseACL {
	using EnumerableSet for EnumerableSet.AddressSet;	

	string public constant NAME = "GMXV2ACL";
	uint256 public constant VERSION = 1;

    address public constant GMX_EXCHANGE_ROUTER = 0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8;
    address public constant GMX_DEPOSIT_VAULT = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
    address public constant GMX_WITHDRAWAL_VAULT = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

	EnumerableSet.AddressSet internal _allowTokens;

	constructor(address caller_, address safeAccount_, address[] memory allowTokens_) BaseACL(caller_) {
		for (uint256 i = 0; i < allowTokens_.length; i++) {
			_allowTokens.add(allowTokens_[i]);
		}
		safeAccount = safeAccount_;
	}

    function multicall(bytes[] calldata data) external view onlyContract(GMX_EXCHANGE_ROUTER) {
        for(uint256 i = 0; i < data.length; ++i) {
            BaseGuard.TxData memory transaction = _unpackTxn();
            transaction.data = data[i];
            require(_check(_packTxn(transaction)), "GMXV2ACL: multicall failed");
        }
    }

    function sendWnt(address receiver, uint256 amount) external view onlyContract(GMX_EXCHANGE_ROUTER) {
        require(receiver == GMX_DEPOSIT_VAULT || receiver == GMX_WITHDRAWAL_VAULT, "GMXV2ACL: Invalid WNT receiver");
    }

    function sendTokens(address token, address receiver, uint256 amount) external view onlyContract(GMX_EXCHANGE_ROUTER) {
        require(receiver == GMX_DEPOSIT_VAULT || receiver == GMX_WITHDRAWAL_VAULT, "GMXV2ACL: Invalid token receiver");
        _checkAllowedToken(token);
    }

    function createDeposit(CreateDepositParams calldata params) external view onlyContract(GMX_EXCHANGE_ROUTER) {
        require(params.receiver == safeAccount, "GMXV2ACL: Invalid Deposit receiver");
        require(params.callbackContract == address(0), "GMXV2ACL: Deposit callback not allowed");
        _checkAllowedToken(params.market);
    }

    function createWithdrawal(CreateWithdrawalParams calldata params) external view onlyContract(GMX_EXCHANGE_ROUTER) {
        require(params.receiver == safeAccount, "GMXV2ACL: Invalid withdrawal receiver");
        require(params.callbackContract == address(0), "GMXV2ACL: Withdrawal callback not allowed");
        _checkAllowedToken(params.market);
    }

    function _check(bytes memory data) internal view returns (bool) {
        (bool success,) = address(this).staticcall(data);
        return success;
    }

    function _checkAllowedToken(address token) internal view {
        require(_allowTokens.contains(token), "GMXV2ACL: token not allowed");
    }

}