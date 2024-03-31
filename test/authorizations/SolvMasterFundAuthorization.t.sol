// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/solv-master-fund/SolvMasterFundAuthorization.sol";
import "../../src/authorizations/solv-master-fund/SolvMasterFundAuthorizationACL.sol";

contract SolvMasterFundAuthorizationTest is AuthorizationTestBase {

    bytes32 internal constant MASTER_FUND_POOL_ID = 0xdd97d94073acb41e4903b3c5711feae0bd3d7325bb4ee234417d1f32138e195e; 
    bytes32 internal constant ALLOWED_POOL_ID_1 = 0x0ef01fb59f931e3a3629255b04ce29f6cd428f674944789288a1264a79c7c931;
    bytes32 internal constant ALLOWED_POOL_ID_2 = 0xe135f7d003b63b78ca886913e05a08145e709eeae2e7f7ba9bc5ba48c37d3e6c;
    bytes32 internal constant DISALLOWED_POOL_ID = 0x9119ceb6bcf974578e868ab65ae20c0d546716a6657eb27dc3a6bf113f0b519c;

    uint256 internal constant MASTER_FUND_SHARE_SLOT = 100229432860259207791054753930335825545008233779453818202187218347441785805150;
    uint256 internal constant ALLOWED_SHARE_SLOT_1 = 6756642026404814179393135527655482004793591833073186990035744963805248473393;
    uint256 internal constant ALLOWED_SHARE_SLOT_2 = 101865744165075658689981121561997632648317109401952010749193799761822599691884;
    uint256 internal constant DISALLOWED_SHARE_SLOT = 65630960907552148646725937468490051646102351480280827518300144258767810941340;

    address internal constant DISALLOWED_SFT = 0x66E6B4C8aa1b8Ca548Cc4EBcd6f3a8c6f4F3d04d;

    SolvMasterFundAuthorization internal _masterFundAuthorization;
    SolvMasterFundAuthorizationACL internal _masterFundAuthorizationACL;

    function setUp() public virtual override {
        super.setUp();

        bytes32[] memory poolIdWhitelist = new bytes32[](2);
        poolIdWhitelist[0] = ALLOWED_POOL_ID_1;
        poolIdWhitelist[1] = ALLOWED_POOL_ID_2;
        _masterFundAuthorization = new SolvMasterFundAuthorization(
            address(_guardian), safeAccount, OPEN_END_FUND_MARKET, poolIdWhitelist
        );
        _authorization = _masterFundAuthorization;

        _masterFundAuthorizationACL = new SolvMasterFundAuthorizationACL(
            address(_guardian), safeAccount, governor, OPEN_END_FUND_MARKET, new bytes32[](0)
        );
    }

    function test_Subscribe() public virtual {
        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", ALLOWED_POOL_ID_1, 1 ether, 0, uint64(block.timestamp + 300));
        _checkFromAuthorization(OPEN_END_FUND_MARKET, 0, txData, Type.CheckResult(true, ""));
    }

    function test_SubscribeWithGivenShareId() public virtual {
        uint256 mockedHoldingSftId = 100;
        _mock_getPoolInfo(ALLOWED_POOL_ID_1, ALLOWED_SHARE_SLOT_1);
        _mock_getSftOwner(OPEN_END_FUND_SHARE, mockedHoldingSftId, safeAccount);

        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", ALLOWED_POOL_ID_1, 1 ether, mockedHoldingSftId, uint64(block.timestamp + 300));
        _checkFromAuthorization(OPEN_END_FUND_MARKET, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Redeem() public virtual {
        uint256 mockedShareId = 100;
        bytes memory txData = abi.encodeWithSignature("requestRedeem(bytes32,uint256,uint256,uint256)", ALLOWED_POOL_ID_1, mockedShareId, 0, 1 ether);
        _checkFromAuthorization(OPEN_END_FUND_MARKET, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevokeRedeem() public virtual {
        uint256 mockedRedemptionId = 100;
        bytes memory txData = abi.encodeWithSignature("revokeRedeem(bytes32,uint256)", ALLOWED_POOL_ID_1, mockedRedemptionId);
        _checkFromAuthorization(OPEN_END_FUND_MARKET, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertWhenSubscribeToUnallowedPool() public virtual {
        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", DISALLOWED_POOL_ID, 1 ether, 0, uint64(block.timestamp + 300));
        _checkFromAuthorization(
            OPEN_END_FUND_MARKET, 0, txData, 
            Type.CheckResult(false, "MasterFundACL: pool not allowed")
        );
    }

    function test_RevertWhenSubscribeToUnheldShareId() public virtual {
        uint256 mockedSftId = 100;
        _mock_getPoolInfo(ALLOWED_POOL_ID_1, ALLOWED_SHARE_SLOT_1);
        _mock_getSftOwner(OPEN_END_FUND_SHARE, mockedSftId, permissionlessAccount);
        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", ALLOWED_POOL_ID_1, 1 ether, mockedSftId, uint64(block.timestamp + 300));
        _checkFromAuthorization(
            OPEN_END_FUND_MARKET, 0, txData, 
            Type.CheckResult(false, "MasterFundACL: invalid share receiver")
        );
    }

    function test_RevertWhenRedeemToUnheldRedemptionId() public virtual {
        uint256 mockedShareId = 100;
        uint256 mockedRedemptionId = 200;
        _mock_getPoolInfo(ALLOWED_POOL_ID_1, ALLOWED_SHARE_SLOT_1);
        _mock_getSftOwner(OPEN_END_FUND_REDEMPTION, mockedRedemptionId, permissionlessAccount);

        bytes memory txData = abi.encodeWithSignature("requestRedeem(bytes32,uint256,uint256,uint256)", ALLOWED_POOL_ID_1, mockedShareId, mockedRedemptionId, 1 ether);
        _checkFromAuthorization(
            OPEN_END_FUND_MARKET, 0, txData, 
            Type.CheckResult(false, "MasterFundACL: invalid redemption receiver")
        );
    }

    function test_AddPoolIdWhitelist() public virtual {
        vm.startPrank(governor);
        bytes32[] memory addPoolIds = new bytes32[](2);
        addPoolIds[0] = ALLOWED_POOL_ID_1;
        addPoolIds[1] = ALLOWED_POOL_ID_2;
        _masterFundAuthorizationACL.addPoolIdWhitelist(addPoolIds);
        vm.stopPrank();

        bytes32[] memory actualPoolIds = _masterFundAuthorizationACL.getPoolIdWhitelist();
        assertEq(actualPoolIds.length, 2);
        assertEq(actualPoolIds[0], ALLOWED_POOL_ID_1);
        assertEq(actualPoolIds[1], ALLOWED_POOL_ID_2);

        assertTrue(_masterFundAuthorizationACL.checkPoolId(ALLOWED_POOL_ID_1));
        assertTrue(_masterFundAuthorizationACL.checkPoolId(ALLOWED_POOL_ID_2));
        assertFalse(_masterFundAuthorizationACL.checkPoolId(DISALLOWED_POOL_ID));
    }

    function test_RemovePoolIdWhitelist() public virtual {
        vm.startPrank(governor);
        bytes32[] memory addPoolIds = new bytes32[](2);
        addPoolIds[0] = ALLOWED_POOL_ID_1;
        addPoolIds[1] = ALLOWED_POOL_ID_2;
        _masterFundAuthorizationACL.addPoolIdWhitelist(addPoolIds);

        bytes32[] memory removePoolIds = new bytes32[](1);
        removePoolIds[0] = ALLOWED_POOL_ID_1;
        _masterFundAuthorizationACL.removePoolIdWhitelist(removePoolIds);
        vm.stopPrank();

        bytes32[] memory actualPoolIds = _masterFundAuthorizationACL.getPoolIdWhitelist();
        assertEq(actualPoolIds.length, 1);
        assertEq(actualPoolIds[0], ALLOWED_POOL_ID_2);

        assertTrue(_masterFundAuthorizationACL.checkPoolId(ALLOWED_POOL_ID_2));
        assertFalse(_masterFundAuthorizationACL.checkPoolId(ALLOWED_POOL_ID_1));
        assertFalse(_masterFundAuthorizationACL.checkPoolId(DISALLOWED_POOL_ID));
    }

    /** Internal Functions */

    function _mock_getPoolInfo(bytes32 poolId, uint256 shareSlot) internal {
        IOpenFundMarket.PoolInfo memory mockPoolInfo = IOpenFundMarket.PoolInfo(
            IOpenFundMarket.PoolSFTInfo(OPEN_END_FUND_SHARE, OPEN_END_FUND_REDEMPTION, shareSlot, 12345678),
            IOpenFundMarket.PoolFeeInfo(0, address(0), 0),
            IOpenFundMarket.ManagerInfo(makeAddr("POOL_MANAGER"), makeAddr("SUBSCRIBE_NAV_MANAGER"), makeAddr("REDEEM_NAV_MANAGER")),
            IOpenFundMarket.SubscribeLimitInfo(100 ether, 0, type(uint256).max, uint64(block.timestamp), uint64(block.timestamp + 86400)),
            makeAddr("VAULT"), USDT, makeAddr("NAV_ORACLE"), uint64(block.timestamp), true, 0
        );
        vm.mockCall(OPEN_END_FUND_MARKET, abi.encodeWithSignature("poolInfos(bytes32)", poolId), abi.encode(mockPoolInfo));
    }

    function _mock_getSftOwner(address sft, uint256 sftId, address owner) internal {
        vm.mockCall(sft, abi.encodeWithSignature("ownerOf(uint256)", sftId), abi.encode(owner));
    }

}