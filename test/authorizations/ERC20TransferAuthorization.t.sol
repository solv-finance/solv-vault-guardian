// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/common/BaseAuthorization.sol";
import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/ERC20TransferAuthorization.sol";

contract SolvVaultGuardianTest is SolvVaultGuardianBaseTest {
    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();
    }

    function testFail_TransferERC20Token() public {
        vm.startPrank(governor);
        _erc20TransferWithSafe(USDT, CEX_RECHARGE_ADDRESS, 1e6);
        vm.stopPrank();
    }

    function testFail_TransferErc20Token() public {
        ERC20TransferAuthorization.TokenReceivers memory receiver =
            ERC20TransferAuthorization.TokenReceivers({token: USDT, receivers: new address[](1)});
        ERC20TransferAuthorization.TokenReceivers[] memory tokenReceivers =
            new ERC20TransferAuthorization.TokenReceivers[](1);
        tokenReceivers[0] = receiver;
        BaseAuthorization erc20TransferAuth =
            new ERC20TransferAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), tokenReceivers);
        vm.startPrank(governor);
        SolvVaultGuardianForSafe13.Authorization memory auth = SolvVaultGuardianBase.Authorization({
            name: "ERC20TransferAuthorization",
            executor: address(erc20TransferAuth),
            enabled: true
        });
        SolvVaultGuardianForSafe13.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](1);
        auths[0] = auth;
        _guardian.addAuthorizations(auths);
        _erc20TransferWithSafe(USDT, CEX_RECHARGE_ADDRESS, 1e6);
        vm.stopPrank();
    }

    function testSuccess_TransferErc20Token() public {
        ERC20TransferAuthorization.TokenReceivers memory receiver =
            ERC20TransferAuthorization.TokenReceivers({token: USDT, receivers: new address[](1)});
        receiver.receivers[0] = CEX_RECHARGE_ADDRESS;
        ERC20TransferAuthorization.TokenReceivers[] memory tokenReceivers =
            new ERC20TransferAuthorization.TokenReceivers[](1);
        tokenReceivers[0] = receiver;
        BaseAuthorization erc20TransferAuth =
            new ERC20TransferAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), tokenReceivers);
        vm.startPrank(governor);
        SolvVaultGuardianBase.Authorization memory auth = SolvVaultGuardianBase.Authorization({
            name: "ERC20TransferAuthorization",
            executor: address(erc20TransferAuth),
            enabled: true
        });
        SolvVaultGuardianBase.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](1);
        auths[0] = auth;
        _guardian.addAuthorizations(auths);
        _erc20TransferWithSafe(USDT, CEX_RECHARGE_ADDRESS, 1e6);
        vm.stopPrank();
    }

    function testSuccess_governorAddTokenReceiver() public {
        vm.startPrank(governor);
        ERC20TransferAuthorization.TokenReceivers[] memory tokenReceivers =
            new ERC20TransferAuthorization.TokenReceivers[](0);

        ERC20TransferAuthorization erc20TransferAuth =
            new ERC20TransferAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), tokenReceivers);
        SolvVaultGuardianBase.Authorization memory auth = SolvVaultGuardianBase.Authorization({
            name: "ERC20TransferAuthorization",
            executor: address(erc20TransferAuth),
            enabled: true
        });
        SolvVaultGuardianBase.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](1);
        auths[0] = auth;
        _guardian.addAuthorizations(auths);

        ERC20TransferAuthorization.TokenReceivers memory receiver =
            ERC20TransferAuthorization.TokenReceivers({token: USDT, receivers: new address[](1)});
        receiver.receivers[0] = CEX_RECHARGE_ADDRESS;
        ERC20TransferAuthorization.TokenReceivers[] memory newTokenReceivers =
            new ERC20TransferAuthorization.TokenReceivers[](1);
        newTokenReceivers[0] = receiver;
        erc20TransferAuth.addTokenReceivers(newTokenReceivers);
        _erc20TransferWithSafe(USDT, CEX_RECHARGE_ADDRESS, 1e6);
        vm.stopPrank();
    }
}
