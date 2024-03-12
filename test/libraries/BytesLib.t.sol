// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/libraries/BytesLib.sol";

contract BytesLibTest is Test {

    using BytesLib for bytes;

    function test_Slice() public virtual {
        bytes memory testBytes = "This is a test for BytesLib";
        assertEq(testBytes.slice(0, 4), "This");
        assertEq(testBytes.slice(5, 10), "is a test ");
    }

    function test_ToAddress() public virtual {
        bytes memory testBytes = abi.encodePacked(0xaBCdeFAbCDEFabcDeFAbcDEFabcDEf1234567890, 0x1234567890AbCDEFaBcDEFabCDEFaBCDefaBCdEF);
        assertEq(testBytes.toAddress(0), 0xaBCdeFAbCDEFabcDeFAbcDEFabcDEf1234567890);
        assertEq(testBytes.toAddress(3), 0xabcdeFaBcdeFAbcDefaBCdEF1234567890123456);
    }

    function test_ToUint24() public virtual {
        bytes memory testBytes = abi.encodePacked("1234567890abcdef");
        assertEq(testBytes.toUint24(0), 3224115);
        assertEq(testBytes.toUint24(4), 3487287);
    }

    function test_RevertWhenSliceOutOfBounds() public virtual {
        bytes memory testBytes = "This is a test for BytesLib";
        vm.expectRevert("slice_outOfBounds");
        testBytes.slice(0, 28);
        vm.expectRevert("slice_outOfBounds");
        testBytes.slice(4, 24);
    }
    
    function test_RevertWhenToAddressOutOfBounds() public virtual {
        bytes memory testBytes = abi.encodePacked(0xaBCdeFAbCDEFabcDeFAbcDEFabcDEf1234567890, 0x1234567890AbCDEFaBcDEFabCDEFaBCDefaBCdEF);
        vm.expectRevert("toAddress_outOfBounds");
        testBytes.toAddress(22);
    }

    function test_RevertWhenToUint24OutOfBounds() public virtual {
        bytes memory testBytes = abi.encodePacked("1234567890abcdef");
        vm.expectRevert("toUint24_outOfBounds");
        testBytes.toUint24(14);
    }
}