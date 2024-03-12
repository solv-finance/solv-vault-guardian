// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/libraries/Path.sol";

contract PathTest is Test {

    using Path for bytes;

    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    bytes internal _singlePoolPath = abi.encodePacked(WETH, uint24(500), USDT);
    bytes internal _doublePoolPath = abi.encodePacked(WETH, uint24(500), USDT, uint24(500), WBTC);
    bytes internal _triplePoolPath = abi.encodePacked(WETH, uint24(500), USDT, uint24(30), USDC, uint24(500), WBTC);

    function test_HasMultiplePools() public virtual {
        assertFalse(_singlePoolPath.hasMultiplePools());
        assertTrue(_doublePoolPath.hasMultiplePools());
        assertTrue(_triplePoolPath.hasMultiplePools());
    }

    function test_NumPools() public virtual {
        assertEq(_singlePoolPath.numPools(), 1);
        assertEq(_doublePoolPath.numPools(), 2);
        assertEq(_triplePoolPath.numPools(), 3);
    }

    function test_DecodeFirstPool() public virtual {
        (address tokenA, address tokenB, uint24 fee) = _singlePoolPath.decodeFirstPool();
        assertEq(tokenA, WETH);
        assertEq(tokenB, USDT);
        assertEq(fee, uint24(500));

        (tokenA, tokenB, fee) = _doublePoolPath.decodeFirstPool();
        assertEq(tokenA, WETH);
        assertEq(tokenB, USDT);
        assertEq(fee, uint24(500));

        (tokenA, tokenB, fee) = _triplePoolPath.decodeFirstPool();
        assertEq(tokenA, WETH);
        assertEq(tokenB, USDT);
        assertEq(fee, uint24(500));
    }

    function test_GetFirstPool() public virtual {
        bytes memory firstPool = _singlePoolPath.getFirstPool();
        assertEq(firstPool, abi.encodePacked(WETH, uint24(500), USDT));
        firstPool = _doublePoolPath.getFirstPool();
        assertEq(firstPool, abi.encodePacked(WETH, uint24(500), USDT));
        firstPool = _triplePoolPath.getFirstPool();
        assertEq(firstPool, abi.encodePacked(WETH, uint24(500), USDT));
    }

    function test_SkipToken() public virtual {
        bytes memory skipResult = _singlePoolPath.skipToken();
        assertEq(skipResult, abi.encodePacked(USDT));
        skipResult = _doublePoolPath.skipToken();
        assertEq(skipResult, abi.encodePacked(USDT, uint24(500), WBTC));
        skipResult = _triplePoolPath.skipToken();
        assertEq(skipResult, abi.encodePacked(USDT, uint24(30), USDC, uint24(500), WBTC));
    }

}