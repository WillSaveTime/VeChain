// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interface/IBridgeToken.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bridge is Pausable, Ownable {
    address public TOKEN_ADDRESS;

    uint256 private _nonce;
    mapping(uint256 => bool) private _processedNonces;

    enum Step {
        Burn,
        Mint
    }

    event Transfer(
        address from,
        address to,
        uint256 amount,
        uint256 date,
        uint256 nonce,
        Step indexed step
    );

    constructor(address _TOKEN_ADDRESS) {
        TOKEN_ADDRESS = _TOKEN_ADDRESS;
    }

    function mint(
        address to,
        uint256 amount,
        uint256 otherChainNonce
    ) external onlyOwner {
        require(
            _processedNonces[otherChainNonce] == false,
            "transfer already processed"
        );
        _processedNonces[otherChainNonce] = true;

        IBridgeToken(TOKEN_ADDRESS).bridgeMint(to, amount);

        emit Transfer(
            msg.sender,
            to,
            amount,
            block.timestamp,
            otherChainNonce,
            Step.Mint
        );
    }

    function burn(address to, uint256 amount) external {
        IBridgeToken(TOKEN_ADDRESS).bridgeBurn(msg.sender, amount);

        emit Transfer(
            msg.sender,
            to,
            amount,
            block.timestamp,
            _nonce,
            Step.Burn
        );
        _nonce++;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
