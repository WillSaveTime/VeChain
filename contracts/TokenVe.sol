// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ExoToken.sol';

contract TokenVe is ExoToken {
  constructor() initializer {}

	function initialize() public initializer {
		__ERC20_init("ExoToken", "EXO");
		__ERC2981_init();
		__Pausable_init();
		__Ownable_init();
	}
}
