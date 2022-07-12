// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './ExoToken.sol';

contract TokenEth is ExoToken {

	function initialize() public initializer {
		__ERC20_init("ExoToken", "EXO");
		__Pausable_init();
		__Ownable_init();
		bridgeAddr = msg.sender;
	}
}
