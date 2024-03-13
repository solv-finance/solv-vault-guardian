// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./SolvVaultGuardianTestBase.sol";
import "../../src/common/BaseACL.sol";
import "../../src/common/FunctionAuthorization.sol";

contract MockTarget {
    function call() public pure {}

    function to(address to_) public pure {}
}

contract MockACL is BaseACL {
    constructor(address governor_) BaseACL(governor_) {}

    function to(address to_) public pure {
        if (to_ != address(0x1)) {
            revert("to is not 0x1");
        }
    }
}

contract MockAuthorization is FunctionAuthorization {
    constructor(address target_, address caller_, address governor_) FunctionAuthorization(caller_, governor_) {
        string[] memory funcs = new string[](1);
        funcs[0] = "call()";
        _addContractFuncs(target_, funcs);
    }
}

contract MockAuthorizationWithout165 {}

abstract contract SolvVaultGuardianTestCommonCase is SolvVaultGuardianTestBase {
    SolvVaultGuardianBase internal _guardian;

    function setUp() public virtual override {
        super.setUp();
        _guardian = _createGuardian(true);
        super._setSafeGuard(address(_guardian));
    }

    function _createGuardian(bool allowSetGuard_) internal virtual returns (SolvVaultGuardianBase);

    function test_GuardianInitialStatus() public virtual {
        assertEq(_guardian.safeAccount(), safeAccount);
        assertTrue(_guardian.allowSetGuard());
        assertFalse(_guardian.allowNativeTokenTransfer());
    }

    /**
     * Test for setGuard function
     */
    function test_SetGuard() public virtual {
        vm.startPrank(governor);
        _guardian.setGuardAllowed(true);
        vm.stopPrank();

        // change to another guard
        _guardian = _createGuardian(true);
        _setSafeGuard(address(_guardian));

        // reset guard
        _setSafeGuard(address(0));
    }

    function test_AllowSetGuardStatus() public virtual {
        vm.startPrank(governor);
        _guardian.setGuardAllowed(true);
        assertTrue(_guardian.allowSetGuard());
        _guardian.setGuardAllowed(false);
        assertFalse(_guardian.allowSetGuard());
        vm.stopPrank();
    }

    function test_SetGuardWhenReenabled() public virtual {
        _guardian = _createGuardian(false);
        _setSafeGuard(address(_guardian));

        vm.startPrank(governor);
        _guardian.setGuardAllowed(true);
        vm.stopPrank();

        _guardian = _createGuardian(true);
        _setSafeGuard(address(_guardian));
    }

    function test_RevertWhenSetGuardIsNotAllowedInInitialState() public virtual {
        _guardian = _createGuardian(false);
        _setSafeGuard(address(_guardian));

        // change to another guard
        _guardian = _createGuardian(false);
        _setSafeGuardShouldRevert(address(_guardian), "SolvVaultGuardian: setGuard disabled");

        // reset guard
        _setSafeGuardShouldRevert(address(0), "SolvVaultGuardian: setGuard disabled");
    }

    function test_RevertWhenSetGuardWhenDisabled() public virtual {
        vm.startPrank(governor);
        _guardian.setGuardAllowed(false);
        vm.stopPrank();

        // change to another guard
        _guardian = _createGuardian(false);
        _setSafeGuardShouldRevert(address(_guardian), "SolvVaultGuardian: setGuard disabled");

        // reset guard
        super._setSafeGuardShouldRevert(address(0), "SolvVaultGuardian: setGuard disabled");
    }

    function test_RevertWhenAllowSetGuardByNonGovernor() public virtual {
        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _guardian.setGuardAllowed(false);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only governor");
        _guardian.setGuardAllowed(true);
        vm.stopPrank();
    }

    /**
     * Test for setModule function
     */
    function test_AllowEnableModuleStatus() public virtual {
        vm.startPrank(governor);
        _guardian.setEnableModule(true);
        assertTrue(_guardian.allowEnableModule());
        _guardian.setEnableModule(false);
        assertFalse(_guardian.allowEnableModule());
        vm.stopPrank();
    }

    function test_SetModuleWhenEnable() public virtual {
        vm.startPrank(governor);
        _guardian.setEnableModule(true);
        vm.stopPrank();
        _setModule(ownerOfSafe);
    }

    function test_RevertEnableModuleWhenDisabled() public virtual {
        vm.startPrank(governor);
        _guardian.setEnableModule(false);
        vm.stopPrank();

        // change to another guard
        _guardian = _createGuardian(false);
        _setModuleShouldRevert(ownerOfSafe, "SolvVaultGuardian: enableModule disabled");
    }

    /**
     * Tests for native token transfer
     */
    function test_TransferNativeToken1() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafe(CEX_RECHARGE_ADDRESS, 1 ether);
    }

    function test_NativeTokenTransferStatus() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        assertTrue(_guardian.allowNativeTokenTransfer());
        assertTrue(_guardian.nativeTokenReceiver(CEX_RECHARGE_ADDRESS));

        _guardian.removeNativeTokenReceiver(receiverWhitelist);
        assertFalse(_guardian.nativeTokenReceiver(CEX_RECHARGE_ADDRESS));

        _guardian.setNativeTokenTransferAllowed(false);
        assertFalse(_guardian.allowNativeTokenTransfer());
        vm.stopPrank();
    }

    function test_TransferNativeTokenToSelf() public virtual {
        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafe(safeAccount, 1 ether);
    }

    function test_RevertWhenTransferNativeTokenInInitialState() public virtual {
        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafeShouldRevert(
            CEX_RECHARGE_ADDRESS, 1 ether, "SolvVaultGuardian: native token transfer not allowed"
        );

        // when transfer value is zero
        super._nativeTokenTransferWithSafeShouldRevert(
            CEX_RECHARGE_ADDRESS, 0, "SolvVaultGuardian: native token transfer not allowed"
        );
    }

    function test_RevertWhenReceiverIsNotInWhitelist() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();

        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafeShouldRevert(
            CEX_RECHARGE_ADDRESS, 1 ether, "SolvVaultGuardian: native token receiver not allowed"
        );

        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = governor;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        super._nativeTokenTransferWithSafeShouldRevert(
            CEX_RECHARGE_ADDRESS, 1 ether, "SolvVaultGuardian: native token receiver not allowed"
        );
    }

    function test_RevertWhenTransferNativeTokenIsDisabled() public virtual {
        vm.startPrank(governor);
        _guardian.setNativeTokenTransferAllowed(true);
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        _guardian.setNativeTokenTransferAllowed(false);
        vm.stopPrank();

        hoax(safeAccount, 10 ether);
        super._nativeTokenTransferWithSafeShouldRevert(
            CEX_RECHARGE_ADDRESS, 1 ether, "SolvVaultGuardian: native token transfer not allowed"
        );
    }

    function test_RevertWhenAllowTransferNativeTokenByNonGovernor() public virtual {
        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only governor");
        _guardian.setNativeTokenTransferAllowed(true);
        vm.stopPrank();
    }

    function test_RevertWhenAddNativeTokenReceiversByNonGovernor() public virtual {
        address[] memory receiverWhitelist = new address[](1);
        receiverWhitelist[0] = CEX_RECHARGE_ADDRESS;

        vm.startPrank(ownerOfSafe);
        vm.expectRevert("Governable: only governor");
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("Governable: only governor");
        _guardian.addNativeTokenReceiver(receiverWhitelist);
        vm.stopPrank();
    }

    /**
     * Tests for updating authorization
     */
    function test_AddAndRemoveAuthorization() public virtual {
        address target = address(new MockTarget());
        address authorization = address(new MockAuthorization(target, address(_guardian), governor));

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(
            target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))), "SolvVaultGuardian: unauthorized contract"
        );
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.setAuthorization(target, authorization);
        vm.stopPrank();
        assertEq(_guardian.getAllToAddresses().length, 1);

        vm.startPrank(ownerOfSafe);
        _callExecTransaction(target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))));
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.removeAuthorization(target);
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(
            target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))), "SolvVaultGuardian: unauthorized contract"
        );
        vm.stopPrank();
    }

    function test_RevertWhenAuthorizationWithout165() public virtual {
        address target = address(new MockTarget());
        address authorization = address(new MockAuthorizationWithout165());

        vm.startPrank(governor);
        vm.expectRevert();
        _guardian.setAuthorization(target, authorization);
        vm.stopPrank();
    }

    function test_addAndRemoveContractFunc() public virtual {
        address target = address(new MockTarget());
        string[] memory funcs = new string[](1);
        funcs[0] = "call()";

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(
            target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))), "SolvVaultGuardian: unauthorized contract"
        );
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.addContractFuncs(target, address(0), funcs);
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransaction(target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))));
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.removeContractFuncs(target, funcs);
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(
            target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))), "SolvVaultGuardian: unauthorized contract"
        );
        vm.stopPrank();
    }

    function test_addAndRemoveContractFuncSig() public virtual {
        address target = address(new MockTarget());
        bytes4[] memory funcSigs = new bytes4[](1);
        bytes4 funcSig = bytes4(keccak256("call()"));
        funcSigs[0] = funcSig;

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(
            target, 0, abi.encodeWithSelector(funcSig), "SolvVaultGuardian: unauthorized contract"
        );
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.addContractFuncsSig(target, address(0), funcSigs);
        vm.stopPrank();
        assertEq(_guardian.getFunctionsByContract(target).length, 1);
        assertEq(_guardian.getFunctionsByContract(target)[0], funcSig);
        assertEq(_guardian.getAllContracts().length, 1);

        vm.startPrank(ownerOfSafe);
        _callExecTransaction(target, 0, abi.encodeWithSelector(funcSig));
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.removeContractFuncsSig(target, funcSigs);
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(
            target, 0, abi.encodeWithSelector(bytes4(keccak256("call()"))), "SolvVaultGuardian: unauthorized contract"
        );
        vm.stopPrank();
    }

    function test_AddAndRemoveContractACL() public virtual {
        address target = address(new MockTarget());
        address acl = address(new MockACL(address(_guardian)));
        string memory func = "to(address)";
        bytes4 funcSig = bytes4(keccak256("to(address)"));

        string[] memory funcs = new string[](1);
        funcs[0] = func;
        vm.startPrank(governor);
        _guardian.addContractFuncs(target, address(0), funcs);
        vm.stopPrank();
        assertEq(_guardian.getACLByContract(target), address(0));

        vm.startPrank(ownerOfSafe);
        _callExecTransaction(target, 0, abi.encodeWithSelector(funcSig, address(0x2)));
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.setContractACL(target, acl);
        vm.stopPrank();
        assertEq(_guardian.getACLByContract(target), acl);

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(target, 0, abi.encodeWithSelector(funcSig, address(0x2)), "to is not 0x1");
        vm.stopPrank();

        vm.startPrank(governor);
        _guardian.setContractACL(target, address(0));
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransaction(target, 0, abi.encodeWithSelector(funcSig, address(0x2)));
        vm.stopPrank();
    }

    /**
     * Tests for Multicall
     */
    function test_GuardianMulticall() public virtual {
        bytes[] memory allData = new bytes[](3);
        allData[0] = abi.encodeWithSelector(bytes4(keccak256("setGuardAllowed(bool)")), true);
        allData[1] = abi.encodeWithSelector(bytes4(keccak256("setEnableModule(bool)")), true);
        allData[2] = abi.encodeWithSelector(bytes4(keccak256("setNativeTokenTransferAllowed(bool)")), true);
        vm.startPrank(governor);
        _guardian.multicall(allData);
        vm.stopPrank();
    }

    function test_GuardianMulticallShouldRevert() public virtual {
        bytes[] memory allData = new bytes[](3);
        allData[0] = abi.encodeWithSelector(bytes4(keccak256("setGuardAllowed(bool)")), true);
        allData[1] = abi.encodeWithSelector(bytes4(keccak256("setEnableModule(bool)")), true);
        allData[2] = abi.encodeWithSelector(bytes4(keccak256("setNativeTokenTransferAllowed(bool)")), true);
        vm.expectRevert("Governable: only governor");
        _guardian.multicall(allData);
    }

    /**
     * Tests for MultiSend
     */
    function test_MultiSend() public virtual {
        bytes memory tx_1 = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), address(0));
        bytes memory tx_2 = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), address(0));
        bytes memory multiSendData = abi.encodePacked(
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_1.length), tx_1,
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_2.length), tx_2
        );
        bytes memory multiSendTx = abi.encodeWithSelector(bytes4(keccak256("multiSend(bytes)")), multiSendData);

        vm.startPrank(ownerOfSafe);
        _delegatecallExecTransaction(_safeMultiSend, 0, multiSendTx);
        vm.stopPrank();
    }

    function test_NestedMultiSend() public virtual {
        bytes memory tx_1 = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), address(0));
        bytes memory tx_2 = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), address(0));
        bytes memory innerMultiSendData = abi.encodePacked(
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_1.length), tx_1,
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_2.length), tx_2
        );
        bytes memory innerMultiSendTx = abi.encodeWithSelector(bytes4(keccak256("multiSend(bytes)")), innerMultiSendData);

        bytes memory outerMultiSendData = abi.encodePacked(
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_1.length), tx_1,
            bytes1(0x01), _safeMultiSend, uint256(0), uint256(innerMultiSendTx.length), innerMultiSendTx
        );
        bytes memory outerMultiSendTx = abi.encodeWithSelector(bytes4(keccak256("multiSend(bytes)")), outerMultiSendData);

        vm.startPrank(ownerOfSafe);
        _delegatecallExecTransaction(_safeMultiSend, 0, outerMultiSendTx);
        vm.stopPrank();
    }

    function test_RevertWhenAnySendFails() public virtual {
        bytes memory tx_1 = abi.encodeWithSelector(bytes4(keccak256("setGuard(address)")), address(0));
        bytes memory tx_2 = abi.encodeWithSelector(bytes4(keccak256("setGuardAllowed(bool)")), true);
        bytes memory multiSendData = abi.encodePacked(
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_1.length), tx_1,
            bytes1(0x00), safeAccount, uint256(0), uint256(tx_2.length), tx_2
        );
        bytes memory multiSendTx = abi.encodeWithSelector(bytes4(keccak256("multiSend(bytes)")), multiSendData);

        vm.startPrank(ownerOfSafe);
        _delegatecallExecTransactionShouldRevert(_safeMultiSend, 0, multiSendTx, "SolvVaultGuardian: unauthorized contract");
        vm.stopPrank();
    }

    /**
     * Tests for Authorization Checks
     */
    function test_AuthorizationCheckSuccess() public virtual {
        address target = address(new MockTarget());
        address authorization = address(new MockAuthorization(target, address(_guardian), governor));

        vm.startPrank(governor);
        _guardian.setAuthorization(target, authorization);
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransaction(target, 0, abi.encodeWithSignature("call()"));
        vm.stopPrank();
    }

    function test_RevertWhenAuthorizationCheckFail() public virtual {
        address target = address(new MockTarget());
        address authorization = address(new MockAuthorization(target, address(_guardian), governor));

        vm.startPrank(governor);
        _guardian.setAuthorization(target, authorization);
        vm.stopPrank();

        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(target, 0, abi.encodeWithSignature("failCall()"), "FunctionAuthorization: not allowed function");
        vm.stopPrank();
    }

    /**
     * Tests for invalid tx_data length
     */
    function test_RevertWhenDataLengthLessThanFourBytes() public virtual {
        vm.startPrank(ownerOfSafe);
        _callExecTransactionShouldRevert(safeAccount, 0, "err", "FunctionAuthorization: invalid txData");
        vm.stopPrank();
    }
}
