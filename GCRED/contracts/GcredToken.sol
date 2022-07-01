// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract GcredToken is
	Initializable,
	ERC20Upgradeable,
	ERC20BurnableUpgradeable,
	PausableUpgradeable,
	OwnableUpgradeable,
	ERC20PermitUpgradeable,
	ERC20VotesUpgradeable,
  SafeMathUpgradeable
{

  address public admin;
  address public MDwallet = '';
  address public DAOwallet = '';

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function bridgeMint(address to, uint amount) public {
    require(msg.sender == admin, 'only admin');
		_mint(to, amount);
	}

  function bridgeBurn(address owner, uint amount) external {
    require(msg.sender == admin, 'only admin');
    _burn(owner, amount);
  }

  function bridgeUpdateAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }

  function mint(address to, uint amount) public onlyOwner {
		_mint(to, amount);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint amount
	) internal override whenNotPaused {
		super._beforeTokenTransfer(from, to, amount);
	}

	// The following functions are overrides required by Solidity.

	function _afterTokenTransfer(
		address from,
		address to,
		uint amount
	) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
		super._afterTokenTransfer(from, to, amount);
	}

	function _mint(address to, uint amount)
		internal
		override(ERC20Upgradeable, ERC20VotesUpgradeable)
	{
		super._mint(to, amount);
	}

	function _burn(address account, uint amount)
		internal
		override(ERC20Upgradeable, ERC20VotesUpgradeable)
	{
		super._burn(account, amount);
	}

  function transfer(address to, uint256 amount) 
    public 
    virtual 
    override 
    returns (bool) 
  {
    address owner = _msgSender();
    uint MDamount = amount.mul(2).div(100);
    uint burnAmount = amount.mul(3).div(100);
    uint transferAmount = amount.sub(MDamount).sub(burnAmount);

    _transfer(owner, to, transferAmount);
    _transfer(owner, MDwallet, MDamount);
    _burn(owner, burnAmount);
    return true;
  }

  function buy_item(uint256 amount)
    public
    returns(bool)
  {
    address owner = _msgSender();
    uint burnAmount = amount.mul(75).div(100);
    uint MDamount = amount.mul(20).div(100);
    uint DAOamount = amount.mul(5).div(100);
    _transfer(owner, MDwallet, MDamount);
    _transfer(owner, DAOwallet, DAOamount);
    _burn(owner, burnAmount);
    return true;
  }
}