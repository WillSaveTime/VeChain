// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./GcredToken.sol";

contract TokenVe is GcredToken {
		
	function initialize() public initializer {
		__ERC20_init("GcredToken", "Gcred");
		__Pausable_init();
		__Ownable_init();
		admin = msg.sender;
	}
}
