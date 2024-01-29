// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC3525 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOf(uint256 tokenId) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function slotOf(uint256 tokenId) external view returns (uint256);
}