// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract GcredToken is
	Initializable,
	ERC20Upgradeable,
	ERC20BurnableUpgradeable,
	PausableUpgradeable,
	OwnableUpgradeable
{
	address public admin;
	address public MDwallet;
	address public DAOwallet;
    address public EXO;
	using SafeMathUpgradeable for uint256;

    modifier mintAddr() {
        require(msg.sender == EXO);
        _;
    }

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function bridgeMint(address to, uint256 amount) public {
		require(msg.sender == admin, "only admin");
		_mint(to, amount);
	}

	function bridgeBurn(address _owner, uint256 amount) external {
		require(msg.sender == admin, "only admin");
		_burn(_owner, amount);
	}

	function bridgeUpdateAdmin(address newAdmin) external {
		require(msg.sender == admin, "only admin");
		admin = newAdmin;
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override whenNotPaused {
		super._beforeTokenTransfer(from, to, amount);
	}

	// The following functions are overrides required by Solidity.

	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override(ERC20Upgradeable) {
		super._afterTokenTransfer(from, to, amount);
	}

	function _mint(address to, uint256 amount)
		internal
		override(ERC20Upgradeable)
	{
		super._mint(to, amount);
	}

	function _burn(address account, uint256 amount)
		internal
		override(ERC20Upgradeable)
	{
		super._burn(account, amount);
	}

	function changeEXO(address newAddr) 
		public 
		onlyOwner 
	{
		EXO = newAddr;
	}

	function cutomTransfer(address to, uint256 amount)
		public
		returns (bool)
	{
		address _owner = _msgSender();
		uint256 MDamount = amount.mul(2).div(100);
		uint256 burnAmount = amount.mul(3).div(100);
		uint256 transferAmount = amount.sub(MDamount).sub(burnAmount);

		_transfer(_owner, to, transferAmount);
		_transfer(_owner, MDwallet, MDamount);
		_burn(_owner, burnAmount);
		return true;
	}

	function buy_item(uint256 amount) public returns (bool) {
		address _owner = _msgSender();
		uint256 burnAmount = amount.mul(70).div(100);
		uint256 MDamount = amount.mul(25).div(100);
		uint256 DAOamount = amount.mul(5).div(100);
		_transfer(_owner, MDwallet, MDamount);
		_transfer(_owner, DAOwallet, DAOamount);
		_burn(_owner, burnAmount);
		return true;
	}

    function mintForReward(address to, uint256 amount) public mintAddr {
        _mint(to, amount);
    }

	function setMDWallet(address newAddress) public onlyOwner{
		MDwallet = newAddress;
	}

	function setDaoWallet(address newAddress) public onlyOwner{
		DAOwallet = newAddress;
	}
}
