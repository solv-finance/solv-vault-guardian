// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/external/IERC3525.sol";
import "../../src/authorizations/ERC20ApproveAuthorization.sol";
import "../../src/authorizations/ERC3525ApproveAuthorization.sol";
import "../../src/authorizations/solv-master-fund/SolvMasterFundAuthorization.sol";
import "../../src/authorizations/solv-master-fund/SolvMasterFundAuthorizationACL.sol";

contract GMXV2AuthorizationTest is SolvVaultGuardianBaseTest {

    bytes32 internal constant MASTER_FUND_POOL_ID = 0xdd97d94073acb41e4903b3c5711feae0bd3d7325bb4ee234417d1f32138e195e; 
    bytes32 internal constant ALLOWED_POOL_ID_1 = 0x0ef01fb59f931e3a3629255b04ce29f6cd428f674944789288a1264a79c7c931;
    bytes32 internal constant ALLOWED_POOL_ID_2 = 0xe135f7d003b63b78ca886913e05a08145e709eeae2e7f7ba9bc5ba48c37d3e6c;
    bytes32 internal constant DISALLOWED_POOL_ID = 0x9119ceb6bcf974578e868ab65ae20c0d546716a6657eb27dc3a6bf113f0b519c;

    ERC20ApproveAuthorization internal erc20ApproveAuthorization;
    ERC3525ApproveAuthorization internal erc3525ApproveAuthorization;
    SolvMasterFundAuthorization internal masterFundAuthorization;

    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardianForSafe13(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor, true);
        super._setSafeGuard();

        address[] memory usdtSpenders = new address[](1);
        usdtSpenders[0] = OPEN_END_FUND_MARKET;
        ERC20ApproveAuthorization.TokenSpenders[] memory erc20Spenders = new ERC20ApproveAuthorization.TokenSpenders[](1);
        erc20Spenders[0] = ERC20ApproveAuthorization.TokenSpenders({ token: USDT, spenders: usdtSpenders });
        erc20ApproveAuthorization = new ERC20ApproveAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), erc20Spenders);

        address[] memory sftSpenders = new address[](1);
        sftSpenders[0] = OPEN_END_FUND_MARKET;
        ERC3525ApproveAuthorization.TokenSpenders[] memory erc3525Spenders = new ERC3525ApproveAuthorization.TokenSpenders[](2);
        erc3525Spenders[0] = ERC3525ApproveAuthorization.TokenSpenders({ token: OPEN_END_FUND_SHARE, spenders: sftSpenders });
        erc3525Spenders[1] = ERC3525ApproveAuthorization.TokenSpenders({ token: OPEN_END_FUND_REDEMPTION, spenders: sftSpenders });
        erc3525ApproveAuthorization = new ERC3525ApproveAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), erc3525Spenders);

        bytes32[] memory poolIdWhitelist = new bytes32[](2);
        poolIdWhitelist[0] = ALLOWED_POOL_ID_1;
        poolIdWhitelist[1] = ALLOWED_POOL_ID_2;
        masterFundAuthorization = new SolvMasterFundAuthorization(SAFE_MULTI_SEND_CONTRACT, address(_guardian), safeAccount, OPEN_END_FUND_MARKET, poolIdWhitelist);

        _addAuthorizations();
    }

    function _addAuthorizations() internal virtual {
        SolvVaultGuardianBase.Authorization[] memory auths = new SolvVaultGuardianBase.Authorization[](3);
        auths[0] = SolvVaultGuardianBase.Authorization({
            name: "ERC20ApproveAuthorization",
            executor: address(erc20ApproveAuthorization),
            enabled: true
        });
        auths[1] = SolvVaultGuardianBase.Authorization({
            name: "ERC3525ApproveAuthorization",
            executor: address(erc3525ApproveAuthorization),
            enabled: true
        });
        auths[2] = SolvVaultGuardianBase.Authorization({
            name: "SolvMasterFundAuthorization",
            executor: address(masterFundAuthorization),
            enabled: true
        });
        vm.startPrank(governor);
        _guardian.addAuthorizations(auths);
        vm.stopPrank();
    }

    function test_MasterFundAuth_ApproveErc20() public virtual {
        vm.startPrank(ownerOfSafe);
        _erc20ApproveWithSafe(USDT, OPEN_END_FUND_MARKET, 1 ether);
        vm.stopPrank();
    }

    function test_MasterFundAuth_ApproveErc20WhenTokenNotAllowed() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        _erc20ApproveWithSafe(USDC, OPEN_END_FUND_MARKET, 1 ether);
        vm.stopPrank();
    }

    function test_MasterFundAuth_ApproveErc20WhenSpenderNotAllowed() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        _erc20ApproveWithSafe(USDT, permissionlessAccount, 1 ether);
        vm.stopPrank();
    }

    function test_MasterFundAuth_Subscribe_Redeem_Revoke() public virtual {
        vm.startPrank(ownerOfSafe);
        _erc20ApproveWithSafe(USDT, OPEN_END_FUND_MARKET, 1 ether);
        _subscribe(ALLOWED_POOL_ID_1, 2e6, 0);

        uint256 shareCount = IERC3525(OPEN_END_FUND_SHARE).balanceOf(safeAccount);
        uint256 shareId = IERC3525(OPEN_END_FUND_SHARE).tokenOfOwnerByIndex(safeAccount, shareCount - 1);
        uint256 shareValue = IERC3525(OPEN_END_FUND_SHARE).balanceOf(shareId);
        _erc3525ApproveIdWithSafe(OPEN_END_FUND_SHARE, OPEN_END_FUND_MARKET, shareId);
        _requestRedeem(ALLOWED_POOL_ID_1, shareId, 0, shareValue);

        uint256 redemptionCount = IERC3525(OPEN_END_FUND_REDEMPTION).balanceOf(safeAccount);
        uint256 redemptionId = IERC3525(OPEN_END_FUND_REDEMPTION).tokenOfOwnerByIndex(safeAccount, redemptionCount - 1);
        uint256 redemptionValue = IERC3525(OPEN_END_FUND_REDEMPTION).balanceOf(redemptionId);
        assertEq(shareValue, redemptionValue);

        _erc3525ApproveIdWithSafe(OPEN_END_FUND_REDEMPTION, OPEN_END_FUND_MARKET, redemptionId);
        _revokeRedeem(ALLOWED_POOL_ID_1, redemptionId);
        uint256 shareCount1 = IERC3525(OPEN_END_FUND_SHARE).balanceOf(safeAccount);
        uint256 shareId1 = IERC3525(OPEN_END_FUND_SHARE).tokenOfOwnerByIndex(safeAccount, shareCount1 - 1);
        uint256 shareValue1 = IERC3525(OPEN_END_FUND_SHARE).balanceOf(shareId1);
        assertEq(shareValue1, redemptionValue);
        vm.stopPrank();
    }

    function test_MasterFundAuth_SubscribeWhenPoolNotAllowed() public virtual {
        vm.startPrank(ownerOfSafe);
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        _subscribe(DISALLOWED_POOL_ID, 2e6, 0);
        vm.stopPrank();
    }

    function test_MasterFundAuth_SubscribeToUnheldShareId() public virtual {
        vm.startPrank(ownerOfSafe);
        _erc20ApproveWithSafe(USDT, OPEN_END_FUND_MARKET, 1 ether);
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        _subscribe(ALLOWED_POOL_ID_1, 2e6, 2819);
        vm.stopPrank();
    }

    function test_MasterFundAuth_RedeemToUnheldRedemptionId() public virtual {
        vm.startPrank(ownerOfSafe);
        _erc20ApproveWithSafe(USDT, OPEN_END_FUND_MARKET, 1 ether);
        _subscribe(ALLOWED_POOL_ID_1, 2e6, 0);

        uint256 shareCount = IERC3525(OPEN_END_FUND_SHARE).balanceOf(safeAccount);
        uint256 shareId = IERC3525(OPEN_END_FUND_SHARE).tokenOfOwnerByIndex(safeAccount, shareCount - 1);
        uint256 shareValue = IERC3525(OPEN_END_FUND_SHARE).balanceOf(shareId);
        _erc3525ApproveIdWithSafe(OPEN_END_FUND_SHARE, OPEN_END_FUND_MARKET, shareId);
        _revertMessage = "SolvVaultGuardian: checkTransaction failed";
        _requestRedeem(ALLOWED_POOL_ID_1, shareId, 1315, shareValue);
        vm.stopPrank();
    }

    /** Internal Functions */

    function _erc3525ApproveIdWithSafe(address token, address spender, uint256 tokenId) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), spender, tokenId);
        _callExecTransaction(token, 0, data, Enum.Operation.Call);
    }

    function _erc3525ApproveValueWithSafe(address token, uint256 tokenId, address spender, uint256 allowance) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("approve(uint256,address,uint256)")), spender, tokenId, allowance);
        _callExecTransaction(token, 0, data, Enum.Operation.Call);
    }

    function _subscribe(bytes32 poolId, uint256 currencyAmount, uint256 openFundShareId) internal {
        uint64 expireTime = uint64(block.timestamp + 300);
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("subscribe(bytes32,uint256,uint256,uint64)")), poolId, currencyAmount, openFundShareId, expireTime);
        _callExecTransaction(OPEN_END_FUND_MARKET, 0, data, Enum.Operation.Call);
    }

    function _requestRedeem(bytes32 poolId, uint256 openFundShareId, uint256 openFundRedemptionId, uint256 redeemValue) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("requestRedeem(bytes32,uint256,uint256,uint256)")), poolId, openFundShareId, openFundRedemptionId, redeemValue);
        _callExecTransaction(OPEN_END_FUND_MARKET, 0, data, Enum.Operation.Call);
    }

    function _revokeRedeem(bytes32 poolId, uint256 openFundRedemptionId) internal {
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("revokeRedeem(bytes32,uint256)")), poolId, openFundRedemptionId);
        _callExecTransaction(OPEN_END_FUND_MARKET, 0, data, Enum.Operation.Call);
    }

}