// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";
import "../../src/authorizations/gmxv1/GMXV1Authorization.sol";
import "../../src/authorizations/gmxv1/GMXV1AuthorizationACL.sol";

contract GMXV1AuthorizationTest is AuthorizationTestBase {

    address internal constant GMX_REWARD_ROUTER = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    address internal constant GMX_REWARD_ROUTER_V2 = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;

    address internal constant GMBTC = 0x47c031236e19d024b42f8AE6780E44A573170703;
    address internal constant GMETH = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;
    address internal constant GMARB = 0xC25cEf6061Cf5dE5eb761b50E4743c1F5D7E5407;
    address internal constant GMSOL = 0x09400D9DB990D5ed3f35D7be61DfAEB900Af03C9;  // not allowed

    GMXV1Authorization internal _gmxV1Authorization;

    function setUp() public virtual override {
        super.setUp();

        _gmxV1Authorization = new GMXV1Authorization(safeAccount, address(_guardian));
        _authorization = _gmxV1Authorization;
    }

    function test_AuthorizationInitialStatus() public virtual {
        assertEq(_gmxV1Authorization.getACLByContract(GMX_REWARD_ROUTER), address(0));
        assertNotEq(_gmxV1Authorization.getACLByContract(GMX_REWARD_ROUTER_V2), address(0));
    }

    function test_HandleRewards() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "handleRewards(bool,bool,bool,bool,bool,bool,bool)", 
            true, true, true, true, true, true, true
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Claim() public virtual {
        bytes memory txData = abi.encodeWithSignature("claim()");
        _checkFromAuthorization(GMX_REWARD_ROUTER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_Compound() public virtual {
        bytes memory txData = abi.encodeWithSignature("compound()");
        _checkFromAuthorization(GMX_REWARD_ROUTER, 0, txData, Type.CheckResult(true, ""));
    }

    function test_MintAndStakeGlp() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "mintAndStakeGlp(address,uint256,uint256,uint256)",
            WETH, 1 ether, 1 ether, 1 ether
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(true, ""));
    }

    function test_UnstakeAndRedeemGlp() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "unstakeAndRedeemGlp(address,uint256,uint256,address)",
            WETH, 1 ether, 1 ether, safeAccount
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(true, ""));
    }

    function test_MintAndStakeGlpETH() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "mintAndStakeGlpETH(uint256,uint256)",
            1 ether, 1 ether
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(true, ""));
    }

    function test_UnstakeAndRedeemGlpETH() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "unstakeAndRedeemGlpETH(uint256,uint256,address)",
            1 ether, 1 ether, safeAccount
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(true, ""));
    }

    function test_RevertMintAndStakeGlpWithInvalidToken() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "mintAndStakeGlp(address,uint256,uint256,uint256)",
            WSOL, 1 ether, 1 ether, 1 ether
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(false, "GMXV1ACL: token not allowed"));
    }

    function test_RevertWhenUnstakeAndRedeemGlpWithInvalidToken() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "unstakeAndRedeemGlp(address,uint256,uint256,address)",
            WSOL, 1 ether, 1 ether, safeAccount
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(false, "GMXV1ACL: token not allowed"));
    }

    function test_RevertWhenUnstakeAndRedeemGlpToInvalidReceiver() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "unstakeAndRedeemGlp(address,uint256,uint256,address)",
            WETH, 1 ether, 1 ether, permissionlessAccount
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(false, "GMXV1ACL: receiver not safeAccount"));
    }

    function test_RevertWhenUnstakeAndRedeemGlpETHToInvalidReceiver() public virtual {
        bytes memory txData = abi.encodeWithSignature(
            "unstakeAndRedeemGlpETH(uint256,uint256,address)",
            1 ether, 1 ether, permissionlessAccount
        );
        _checkFromAuthorization(GMX_REWARD_ROUTER_V2, 0, txData, Type.CheckResult(false, "GMXV1ACL: receiver not safeAccount"));
    }

}
