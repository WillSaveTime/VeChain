// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPlanetNFT {
  /// @dev Mint Planet NFT
  /// @param to Address to mint
  /// @param tokneId mint Id
  function safeMint(address to, uint256 tokenId) external;
}