// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../common/AuthorizationTestBase.sol";

contract GovernableTest is AuthorizationTestBase {

    address internal _newGovernor;

    function setUp() public virtual override {
        super.setUp();
        _newGovernor = makeAddr("NEW_GOVERNOR");
    }

    function test_Govern() public virtual {
        assertTrue(_guardian.governanceAllowed());

        vm.startPrank(governor);
        _guardian.transferGovernance(_newGovernor);
        vm.stopPrank();
    }

    function test_TransferGovernance() public virtual {
        vm.startPrank(governor);
        _guardian.transferGovernance(_newGovernor);
        vm.stopPrank();

        assertEq(_guardian.governor(), governor);
        assertEq(_guardian.pendingGovernor(), _newGovernor);

        vm.startPrank(_newGovernor);
        _guardian.acceptGovernance();
        vm.stopPrank();

        assertEq(_guardian.governor(), _newGovernor);
        assertEq(_guardian.pendingGovernor(), address(0));
    }

    function test_ForbidGovernance() public virtual {
        assertTrue(_guardian.governanceAllowed());
        vm.startPrank(governor);
        _guardian.forbidGovernance();
        vm.stopPrank();
        assertFalse(_guardian.governanceAllowed());
    }

    function test_RevertWhenTransferGovernanceByNonGovernor() public virtual {
        vm.startPrank(_newGovernor);
        vm.expectRevert("Governable: only governor");
        _guardian.transferGovernance(_newGovernor);
        vm.stopPrank();
    }

    function test_RevertWhenForbidGovernanceByNonGovernor() public virtual {
        vm.startPrank(_newGovernor);
        vm.expectRevert("Governable: only governor");
        _guardian.forbidGovernance();
        vm.stopPrank();
    }

    function test_RevertWhenGovernanceForbidden() public virtual {
        vm.startPrank(governor);
        _guardian.forbidGovernance();
        vm.expectRevert("Governable: only governor");
        _guardian.transferGovernance(_newGovernor);
        vm.stopPrank();
    }

    function test_RevertWhenAcceptGovernanceByNonPendingGovernor() public virtual {
        vm.startPrank(governor);
        _guardian.transferGovernance(_newGovernor);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only pending governor");
        _guardian.acceptGovernance();
        vm.stopPrank();
    }

}