// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "./IOpenFundMarket.sol";

contract OpenFundTestHelper is Test {
    //contract address on arbitrum
    address public constant OPEN_FUND_MARKET = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address public constant OPEN_FUND_SHARES = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    address public constant OPEN_FUND_REDEMPTION = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address public constant OPEN_FUND_ORACLE = 0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD;

    function market() public pure returns (IOpenFundMarket) {
        return IOpenFundMarket(OPEN_FUND_MARKET);
    }

    function createPool(address poolManager_, address vault_, address currency_, address redeemNavManager_)
        public
        returns (bytes32 poolId_)
    {
        IOpenFundMarket.InputPoolInfo memory inputPoolInfo_ = IOpenFundMarket.InputPoolInfo({
            openFundShare: OPEN_FUND_SHARES,
            openFundRedemption: OPEN_FUND_REDEMPTION,
            currency: currency_,
            carryRate: 0,
            vault: vault_,
            valueDate: uint64(block.timestamp + 1),
            carryCollector: address(0x1),
            subscribeNavManager: address(0x1),
            redeemNavManager: redeemNavManager_,
            navOracle: OPEN_FUND_ORACLE,
            createTime: 0,
            whiteList: new address[](0),
            subscribeLimitInfo: IOpenFundMarket.SubscribeLimitInfo({
                hardCap: 1e30,
                subscribeMin: 0,
                subscribeMax: 2 ** 256 - 1,
                fundraisingStartTime: uint64(block.timestamp),
                fundraisingEndTime: uint64(block.timestamp + 3600)
            })
        });

        vm.startPrank(poolManager_);
        poolId_ = IOpenFundMarket(OPEN_FUND_MARKET).createPool(inputPoolInfo_);
        vm.stopPrank();
    }
}
