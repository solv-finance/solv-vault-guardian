// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/SolvVaultGuardianBaseTest.sol";
import "../../src/authorizations/ERC20TransferAuthorization.sol";

contract GMXV2Authorization is SolvVaultGuardianBaseTest {
    function setUp() public virtual override {
        super.setUp();
        _guardian = new SolvVaultGuardian(safeAccount, SAFE_MULTI_SEND_CONTRACT, governor);
        super._setSafeGuard();
    }
}
