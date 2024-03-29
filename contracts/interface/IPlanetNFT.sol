// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title interface for Governance token EXO
/// @author Tamer Fouad
interface IPlanetNFT {
  /// @dev Mint Planet NFT
  /// @param to Address to mint
  /// @param tokenId mint Id
  function safeMint(address to, uint256 tokenId) external;
}