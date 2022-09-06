// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title interface for game token GCRED
/// @author Tamer Fouad
interface IGCREDToken {
    /// @dev Mint GCRED via bridge
    /// @param to Address to mint
    /// @param amount Token amount to mint
    function bridgeMint(address to, uint256 amount) external;

    /// @dev Burn GCRED via bridge
    /// @param owner Address to burn
    /// @param amount Token amount to burn
    function bridgeBurn(address owner, uint256 amount) external;

    /// @dev Mint GCRED via EXO for daily reward
    /// @param to Address to mint
    /// @param amount Token amount to mint
    function mintForReward(address to, uint256 amount) external;

    /**
     * @dev Set EXO token address
     * @param _EXO_ADDRESS EXO token address
     *
     * Emits a {EXOAddressUpdated} event
     */
    function setEXOAddress(address _EXO_ADDRESS) external;

    /**
     * @dev Set MD(Metaverse Development) wallet address
     * @param _MD_ADDRESS MD wallet address
     *
     * Emits a {MDAddressUpdated} event
     */
    function setMDAddress(address _MD_ADDRESS) external;

    /**
     * @dev Set DAO wallet address
     * @param _DAO_ADDRESS DAO wallet address
     *
     * Emits a {DAOAddressUpdated} event
     */
    function setDAOAddress(address _DAO_ADDRESS) external;
}
