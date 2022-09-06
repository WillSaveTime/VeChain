// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title interface of base token for bridge
/// @author Tamer Fouad
interface IBridgeToken {
    /// @dev Mint EXO/GCRED via bridge
    /// @param to Address to mint
    /// @param amount Token amount to mint
    function bridgeMint(address to, uint256 amount) external;

    /// @dev Burn EXO/GCRED via bridge
    /// @param owner Address to burn
    /// @param amount Token amount to burn
    function bridgeBurn(address owner, uint256 amount) external;
}
