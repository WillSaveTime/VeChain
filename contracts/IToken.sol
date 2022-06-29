// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function bridgeMint(address to, uint amount) external;
  function bridgeBurn(address owner, uint amount) external;
}
