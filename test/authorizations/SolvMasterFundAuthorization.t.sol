// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/external/IERC3525.sol";
import "../../src/external/IOpenFundMarket.sol";
import "../../src/authorizations/solv-master-fund/SolvMasterFundAuthorization.sol";
import "../../src/authorizations/solv-master-fund/SolvMasterFundAuthorizationACL.sol";

contract SolvMasterFundAuthorizationTest is SolvVaultGuardianBaseTest {

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

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        bytes32[] memory poolIdWhitelist = new bytes32[](2);
        poolIdWhitelist[0] = ALLOWED_POOL_ID_1;
        poolIdWhitelist[1] = ALLOWED_POOL_ID_2;
        _masterFundAuthorization = new SolvMasterFundAuthorization(address(_guardian), safeAccount, OPEN_END_FUND_MARKET, poolIdWhitelist);

        _addAuthorizations();
    }

    function test_Subscribe() public virtual {
        vm.startPrank(ownerOfSafe);
        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", ALLOWED_POOL_ID_1, 1 ether, 0, uint64(block.timestamp + 300));
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_SubscribeWithGivenShareId() public virtual {
        vm.startPrank(ownerOfSafe);
        uint256 mockedHoldingSftId = 100;
        _mock_getPoolInfo(ALLOWED_POOL_ID_1, ALLOWED_SHARE_SLOT_1);
        _mock_getSftOwner(OPEN_END_FUND_SHARE, mockedHoldingSftId, safeAccount);

        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", ALLOWED_POOL_ID_1, 1 ether, mockedHoldingSftId, uint64(block.timestamp + 300));
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_Redeem() public virtual {
        vm.startPrank(ownerOfSafe);
        uint256 mockedShareId = 100;
        bytes memory txData = abi.encodeWithSignature("requestRedeem(bytes32,uint256,uint256,uint256)", ALLOWED_POOL_ID_1, mockedShareId, 0, 1 ether);
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevokeRedeem() public virtual {
        vm.startPrank(ownerOfSafe);
        uint256 mockedRedemptionId = 100;
        bytes memory txData = abi.encodeWithSignature("revokeRedeem(bytes32,uint256)", ALLOWED_POOL_ID_1, mockedRedemptionId);
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenApproveUnauthorizedErc20() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(USDC, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, 1 ether), Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenApproveErc20ToUnauthorizedSpender() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        _checkFromGuardian(USDT, 0, abi.encodeWithSignature("approve(address,uint256)", permissionlessAccount, 1 ether), Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenApproveUnauthorizedErc3525() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        uint256 mockedHoldingSftId = 100;
        _checkFromGuardian(DISALLOWED_SFT, 0, abi.encodeWithSignature("approve(address,uint256)", OPEN_END_FUND_MARKET, mockedHoldingSftId), Enum.Operation.Call);
        _checkFromGuardian(DISALLOWED_SFT, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", mockedHoldingSftId, OPEN_END_FUND_MARKET, 1 ether), Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenApproveErc3525ToUnauthorizedSpender() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: unauthorized contract";
        uint256 mockedHoldingSftId = 100;
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(address,uint256)", permissionlessAccount, mockedHoldingSftId), Enum.Operation.Call);
        _checkFromGuardian(OPEN_END_FUND_SHARE, 0, abi.encodeWithSignature("approve(uint256,address,uint256)", mockedHoldingSftId, permissionlessAccount, 1 ether), Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenSubscribeToUnallowedPool() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "MasterFundACL: pool not allowed";
        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", DISALLOWED_POOL_ID, 1 ether, 0, uint64(block.timestamp + 300));
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenSubscribeToUnheldShareId() public virtual {
        vm.startPrank(ownerOfSafe);
        uint256 mockedSftId = 100;
        _mock_getPoolInfo(ALLOWED_POOL_ID_1, ALLOWED_SHARE_SLOT_1);
        _mock_getSftOwner(OPEN_END_FUND_SHARE, mockedSftId, permissionlessAccount);
        _revertMessage = "MasterFundACL: invalid share receiver";
        bytes memory txData = abi.encodeWithSignature("subscribe(bytes32,uint256,uint256,uint64)", ALLOWED_POOL_ID_1, 1 ether, mockedSftId, uint64(block.timestamp + 300));
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    function test_RevertWhenRedeemToUnheldRedemptionId() public virtual {
        vm.startPrank(ownerOfSafe);
        uint256 mockedShareId = 100;
        uint256 mockedRedemptionId = 200;
        _mock_getPoolInfo(ALLOWED_POOL_ID_1, ALLOWED_SHARE_SLOT_1);
        _mock_getSftOwner(OPEN_END_FUND_REDEMPTION, mockedRedemptionId, permissionlessAccount);

        _revertMessage = "MasterFundACL: invalid redemption receiver";
        bytes memory txData = abi.encodeWithSignature("requestRedeem(bytes32,uint256,uint256,uint256)", ALLOWED_POOL_ID_1, mockedShareId, mockedRedemptionId, 1 ether);
        _checkFromGuardian(OPEN_END_FUND_MARKET, 0, txData, Enum.Operation.Call);
        vm.stopPrank();
    }

    /** Internal Functions */

    function _addAuthorizations() internal virtual {
        vm.startPrank(governor);
        _guardian.setAuthorization(OPEN_END_FUND_MARKET, address(_masterFundAuthorization));
        vm.stopPrank();
    }

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