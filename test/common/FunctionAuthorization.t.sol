// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "./AuthorizationTestBase.sol";
import "../../src/common/FunctionAuthorization.sol";
import "../../src/common/BaseACL.sol";

contract FunctionAuthorizationMock is FunctionAuthorization {
    constructor(
        address caller_,
        address governor_
    ) FunctionAuthorization(caller_, governor_) {}

    function addContractFuncsWithACL(address contract_, address acl_, string[] memory funcList_) external {
        _addContractFuncsWithACL(contract_, acl_, funcList_);
    }

    function addContractFuncsSigWithACL(address contract_, address acl_, bytes4[] calldata funcSigList_) external {
        _addContractFuncsSigWithACL(contract_, acl_, funcSigList_);
    }

    function removeContractFuncs(address contract_, string[] memory funcList_) external {
        _removeContractFuncs(contract_, funcList_);
    }

    function removeContractFuncsSig(address contract_, bytes4[] calldata funcSigList_) external {
        _removeContractFuncsSig(contract_, funcSigList_);
    }

    function setContractACL(address contract_, address acl_) external {
        _setContractACL(contract_, acl_);
    }

    function isAllowedSelector(address target_, bytes4 selector_) external view returns (bool) {
        return _isAllowedSelector(target_, selector_);
    }
}

contract ACLMock is BaseACL {
    constructor(address caller_) BaseACL(caller) {}
}

contract FakeACLMock is BaseACL {
    constructor(address caller_) BaseACL(caller) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract FunctionAuthorizationTest is AuthorizationTestBase {

    FunctionAuthorizationMock internal _mockAuthorization;

    address internal _contract_1;
    address internal _contract_2;
    address internal _acl_1;
    address internal _acl_2;
    address internal _fake_acl;
    
    string internal _func_1;
    string internal _func_2;
    bytes4 internal _funcSig_1;
    bytes4 internal _funcSig_2;

    function setUp() public virtual override {
        super.setUp();
        _mockAuthorization = new FunctionAuthorizationMock(address(_guardian), governor);
        _authorization = _mockAuthorization;

        _contract_1 = makeAddr("TEST_CONTRACT_1");
        _contract_2 = makeAddr("TEST_CONTRACT_2");
        _acl_1 = address(new ACLMock(address(_guardian)));
        _acl_2 = address(new ACLMock(address(_guardian)));
        _fake_acl = address(new FakeACLMock(address(_guardian)));

        _func_1 = "approve(address,uint256)";
        _func_2 = "transfer(address,uint256)";
        _funcSig_1 = bytes4(keccak256(bytes(_func_1)));
        _funcSig_2 = bytes4(keccak256(bytes(_func_2)));
    }

    function test_SupportsInterface() public virtual {
        assertTrue(_authorization.supportsInterface(type(IERC165).interfaceId));
        assertTrue(_authorization.supportsInterface(type(IBaseAuthorization).interfaceId));
        assertFalse(_authorization.supportsInterface(type(IBaseACL).interfaceId));
    }

    function test_Fallback() public virtual {
        (bool success /* bytes memory data */, ) = address(_authorization).call(
            abi.encodeWithSignature("callInvalidFunction()")
        );
        assertTrue(success);
    }

    function test_OnlyCaller() public virtual {
        Type.TxData memory txData = Type.TxData({
            from: address(0),
            to: address(0),
            value: 0,
            data: new bytes(0)
        });

        vm.startPrank(permissionlessAccount);
        vm.expectRevert("BaseAuthorization: only caller");
        _authorization.authorizationCheckTransaction(txData);
        vm.stopPrank();
    }

    function test_AddFuncsSigWithAcls() public virtual {
        bytes4[] memory funcsSig = new bytes4[](1);
        funcsSig[0] = _funcSig_1;
        _mockAuthorization.addContractFuncsSigWithACL(_contract_1, _acl_1, funcsSig);

        address[] memory actualContracts = _mockAuthorization.getAllContracts();
        assertEq(actualContracts.length, 1);
        assertEq(actualContracts[0], _contract_1);

        bytes32[] memory actualFuncsSig = _mockAuthorization.getFunctionsByContract(_contract_1);
        assertEq(actualFuncsSig.length, 1);
        assertEq(bytes4(actualFuncsSig[0]), _funcSig_1);

        assertEq(_mockAuthorization.getACLByContract(_contract_1), _acl_1);
        assertTrue(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_1));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_2));
    }

    function test_AddFuncsSigWithNoAcl() public virtual {
        bytes4[] memory funcsSig = new bytes4[](1);
        funcsSig[0] = _funcSig_1;
        _mockAuthorization.addContractFuncsSigWithACL(_contract_1, address(0), funcsSig);

        address[] memory actualContracts = _mockAuthorization.getAllContracts();
        assertEq(actualContracts.length, 1);
        assertEq(actualContracts[0], _contract_1);

        bytes32[] memory actualFuncsSig = _mockAuthorization.getFunctionsByContract(_contract_1);
        assertEq(actualFuncsSig.length, 1);
        assertEq(bytes4(actualFuncsSig[0]), _funcSig_1);

        assertEq(_mockAuthorization.getACLByContract(_contract_1), address(0));
        assertTrue(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_1));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_2));
    }

    function test_AddFuncsWithAcls() public virtual {
        string[] memory funcs = new string[](1);
        funcs[0] = _func_1;
        _mockAuthorization.addContractFuncsWithACL(_contract_1, _acl_1, funcs);

        address[] memory actualContracts = _mockAuthorization.getAllContracts();
        assertEq(actualContracts.length, 1);
        assertEq(actualContracts[0], _contract_1);

        bytes32[] memory actualFuncsSig = _mockAuthorization.getFunctionsByContract(_contract_1);
        assertEq(actualFuncsSig.length, 1);
        assertEq(bytes4(actualFuncsSig[0]), _funcSig_1);

        assertEq(_mockAuthorization.getACLByContract(_contract_1), _acl_1);
        assertTrue(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_1));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_2));
    }

    function test_AddFuncsWithNoAcl() public virtual {
        string[] memory funcs = new string[](1);
        funcs[0] = _func_1;
        _mockAuthorization.addContractFuncsWithACL(_contract_1, address(0), funcs);

        address[] memory actualContracts = _mockAuthorization.getAllContracts();
        assertEq(actualContracts.length, 1);
        assertEq(actualContracts[0], _contract_1);

        bytes32[] memory actualFuncsSig = _mockAuthorization.getFunctionsByContract(_contract_1);
        assertEq(actualFuncsSig.length, 1);
        assertEq(bytes4(actualFuncsSig[0]), _funcSig_1);

        assertEq(_mockAuthorization.getACLByContract(_contract_1), address(0));
        assertTrue(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_1));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_2));
    }

    function test_RemoveFuncsSig() public virtual {
        bytes4[] memory funcsSig = new bytes4[](1);
        funcsSig[0] = _funcSig_1;
        _mockAuthorization.addContractFuncsSigWithACL(_contract_1, _acl_1, funcsSig);
        _mockAuthorization.removeContractFuncsSig(_contract_1, funcsSig);

        address[] memory actualContracts = _mockAuthorization.getAllContracts();
        assertEq(actualContracts.length, 0);

        bytes32[] memory actualFuncsSig = _mockAuthorization.getFunctionsByContract(_contract_1);
        assertEq(actualFuncsSig.length, 0);

        assertEq(_mockAuthorization.getACLByContract(_contract_1), address(0));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_1));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_2));
    }

    function test_RemoveFuncs() public virtual {
        string[] memory funcs = new string[](1);
        funcs[0] = _func_1;
        _mockAuthorization.addContractFuncsWithACL(_contract_1, _acl_1, funcs);
        _mockAuthorization.removeContractFuncs(_contract_1, funcs);

        address[] memory actualContracts = _mockAuthorization.getAllContracts();
        assertEq(actualContracts.length, 0);

        bytes32[] memory actualFuncsSig = _mockAuthorization.getFunctionsByContract(_contract_1);
        assertEq(actualFuncsSig.length, 0);

        assertEq(_mockAuthorization.getACLByContract(_contract_1), address(0));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_1));
        assertFalse(_mockAuthorization.isAllowedSelector(_contract_1, _funcSig_2));
    }

    function test_SetAcl() public virtual {
        string[] memory funcs = new string[](1);
        funcs[0] = _func_1;
        _mockAuthorization.addContractFuncsWithACL(_contract_1, _acl_1, funcs);
        _mockAuthorization.setContractACL(_contract_1, _acl_2);
        assertEq(_mockAuthorization.getACLByContract(_contract_1), _acl_2);
    }

    function test_RevertWhenAddEmptyFuncsSig() public virtual {
        bytes4[] memory funcsSig = new bytes4[](0);
        vm.expectRevert("FunctionAuthorization: empty funcList");
        _mockAuthorization.addContractFuncsSigWithACL(_contract_1, address(0), funcsSig);
    }

    function test_RevertWhenAddEmptyFuncs() public virtual {
        string[] memory funcs = new string[](0);
        vm.expectRevert("FunctionAuthorization: empty funcList");
        _mockAuthorization.addContractFuncsWithACL(_contract_1, address(0), funcs);
    }

    function test_RevertWhenRemoveEmptyFuncsSig() public virtual {
        bytes4[] memory funcsSig = new bytes4[](0);
        vm.expectRevert("FunctionAuthorization: empty funcList");
        _mockAuthorization.removeContractFuncsSig(_contract_1, funcsSig);
    }

    function test_RevertWhenRemoveEmptyFuncs() public virtual {
        string[] memory funcs = new string[](0);
        vm.expectRevert("FunctionAuthorization: empty funcList");
        _mockAuthorization.removeContractFuncs(_contract_1, funcs);
    }

    function test_RevertWhenSetAclToUnauthorizedContract() public virtual {
        vm.expectRevert("FunctionAuthorization: contract not exist");
        _mockAuthorization.setContractACL(_contract_1, _acl_1);
    }

    function test_RevertWhenSetInvalidAcl() public virtual {
        string[] memory funcs = new string[](1);
        funcs[0] = _func_1;
        _mockAuthorization.addContractFuncsWithACL(_contract_1, _acl_1, funcs);

        vm.expectRevert("FunctionAuthorization: acl_ is not IBaseACL");
        _mockAuthorization.setContractACL(_contract_1, _fake_acl);
        vm.expectRevert("FunctionAuthorization: acl_ is not IBaseACL");
        _mockAuthorization.addContractFuncsWithACL(_contract_1, _fake_acl, funcs);
    }

}
