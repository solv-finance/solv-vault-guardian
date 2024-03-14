// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/common/FunctionAuthorization.sol";
import "../../src/common/SolvVaultGuardianBase.sol";

abstract contract AuthorizationTestBase is Test {

    address public constant OPEN_END_FUND_MARKET = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address public constant OPEN_END_FUND_SHARE = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    address public constant OPEN_END_FUND_REDEMPTION = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address public constant CEX_RECHARGE_ADDRESS = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address public constant WSOL = 0x2bcC6D6CdBbDC0a4071e48bb3B969b06B3330c07;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address payable public safeAccount;
    address public ownerOfSafe;
    address public governor;
    address public permissionlessAccount;

    address internal MULTI_SEND_CONTRACT;

    SolvVaultGuardianBase internal _guardian;
    FunctionAuthorization internal _authorization; 

    function setUp() public virtual {
        safeAccount = payable(makeAddr("SAFE_ACCOUNT"));
        ownerOfSafe = makeAddr("OWNER_OF_SAFE");
        governor = makeAddr("GOVERNOR");
        permissionlessAccount = makeAddr("PERMISSIONLESS_ACCOUNT");
        MULTI_SEND_CONTRACT = makeAddr("MULTI_SEND_CONTRACT");

        _guardian = new SolvVaultGuardianBase(safeAccount, MULTI_SEND_CONTRACT, governor, true);
    }

    function _checkFromAuthorization(
        address to, uint256 value, bytes memory data, Type.CheckResult memory expectedCheckResult
    ) internal virtual {
        Type.TxData memory txData = Type.TxData({ 
            from: ownerOfSafe, 
            to: to, 
            value: value, 
            data: data 
        });
        
        vm.startPrank(address(_guardian));
        Type.CheckResult memory actualCheckResult = _authorization.authorizationCheckTransaction(txData);
        vm.stopPrank();

        assertEq(expectedCheckResult.success, actualCheckResult.success);
        assertEq(expectedCheckResult.message, actualCheckResult.message);
    }

}