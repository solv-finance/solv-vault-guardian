// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "./common/SolvVaultGuardianBaseTest.sol";
import "./external/OpenFundTestHelper.sol";
import "./external/IOpenFundRedemption.sol";
import "../src/authorizations/ERC20TransferAuthorization.sol";
import "../src/authorizations/ERC20ApproveAuthorization.sol";
import "../src/authorizations/SolvOpenEndFundAuthorization.sol";
import "../src/common/BaseAuthorization.sol";

contract CEXArbitrageFullFlowTest is SolvVaultGuardianBaseTest {
    OpenFundTestHelper public helper;
    IOpenFundMarket public market;
    address public poolManager;
    address public redeemNavManager;
    address public buyer;
    address public vault;
    bytes32 public openFundPool;
    address public openFundShares;
    address public openFundRedemption;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        poolManager = ownerOfSafe;
        redeemNavManager = ownerOfSafe;
        buyer = permissionlessAccount;
        vault = safeAccount;
        helper = new OpenFundTestHelper();
        market = helper.market();
        openFundPool = helper.createPool(poolManager, vault, USDT, redeemNavManager);
        openFundShares = helper.OPEN_FUND_SHARES();
        openFundRedemption = helper.OPEN_FUND_REDEMPTION();
    }

    function test_CEXArbitrageFullFlow() public virtual {
        //set authorizations
        _addERC20TransferAuthrization();
        _addERC20ApproveAuthrization();
        _addSolvOpenFundAuthorization();

        deal(address(USDT), buyer, 1000 * 1e18);

        //buy and redeem
        vm.startPrank(buyer);
        IERC20(USDT).approve(address(market), 1000 * 1e18);
        market.subscribe(openFundPool, 1000 * 1e18, 0, uint64(block.timestamp + 1000));
        uint256 tokenId = IERC721Enumerable(openFundShares).tokenOfOwnerByIndex(buyer, 0);
        skip(1000);
        IERC721(openFundShares).approve(address(market), tokenId);
        market.requestRedeem(openFundPool, tokenId, 0, 1000 * 1e18);
        vm.stopPrank();

        //transfer to recharge address
        _erc20TransferWithSafe(USDT, CEX_RECHARGE_ADDRESS, 1000 * 1e18);

        //close redeem slot
        skip(1000);
        vm.startPrank(poolManager);
        market.closeCurrentRedeemSlot(openFundPool);
        vm.stopPrank();

        //set redeem nav
        uint256 redeemSlot = market.previousRedeemSlot(openFundPool);
        vm.startPrank(redeemNavManager);
        market.setRedeemNav(openFundPool, redeemSlot, 1e18, 1000 * 1e18);
        vm.stopPrank();

        //from CEX_RECHARGE_ADDRESS transfer to vault
        vm.startPrank(CEX_RECHARGE_ADDRESS);
        IERC20(USDT).transfer(vault, 1000 * 1e18);
        vm.stopPrank();

        //repay
        vm.startPrank(ownerOfSafe);
        _erc20ApproveWithSafe(USDT, address(openFundRedemption), 1000 * 1e18);
        bytes memory data =
            abi.encodeWithSelector(bytes4(keccak256("repay(uint256,address,uint256)")), redeemSlot, USDT, 1000 * 1e18);
        _callExecTransaction(address(openFundRedemption), 0, data, Enum.Operation.Call);
        vm.stopPrank();
    }

    function _addERC20TransferAuthrization() internal virtual {
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
        vm.stopPrank();
    }

    function _addERC20ApproveAuthrization() internal virtual {
        ERC20ApproveAuthorization.TokenSpenders memory spender =
            ERC20ApproveAuthorization.TokenSpenders({token: USDT, spenders: new address[](2)});
        spender.spenders[0] = openFundRedemption;
        spender.spenders[1] = openFundShares;
        ERC20ApproveAuthorization.TokenSpenders[] memory tokenSpenders =
            new ERC20ApproveAuthorization.TokenSpenders[](1);
        tokenSpenders[0] = spender;
        BaseAuthorization erc20ApproveAuth =
            new ERC20ApproveAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), tokenSpenders);
        SolvVaultGuardianBase.Authorization memory auth = SolvVaultGuardianBase.Authorization({
            name: "ERC20ApproveAuthorization",
            executor: address(erc20ApproveAuth),
            enabled: true
        });
        SolvVaultGuardianBase.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](1);
        auths[0] = auth;
        vm.startPrank(governor);
        _guardian.addAuthorizations(auths);
        vm.stopPrank();
    }

    function _addSolvOpenFundAuthorization() internal virtual {
        bytes32[] memory repayablePoolIds = new bytes32[](1);
        repayablePoolIds[0] = openFundPool;
        SolvOpenEndFundAuthorization solvOpenEndFundAuthorization =
        new SolvOpenEndFundAuthorization( SAFE_MULTI_SEND_CONTRACT, address(_guardian), openFundShares, openFundRedemption, repayablePoolIds);
        SolvVaultGuardianBase.Authorization memory auth = SolvVaultGuardianBase.Authorization({
            name: "SolvOpenFundAuthorization",
            executor: address(solvOpenEndFundAuthorization),
            enabled: true
        });
        SolvVaultGuardianBase.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](1);
        auths[0] = auth;
        vm.startPrank(governor);
        _guardian.addAuthorizations(auths);
        vm.stopPrank();
    }
}
