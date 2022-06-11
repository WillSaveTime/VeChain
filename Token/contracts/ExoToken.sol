// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract ExoToken is
	Initializable,
	ERC20Upgradeable,
	ERC20BurnableUpgradeable,
	PausableUpgradeable,
	OwnableUpgradeable,
	ERC20PermitUpgradeable,
	ERC20VotesUpgradeable,
	ERC2981Upgradeable
{
  /// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	function initialize() public initializer {
		__ERC20_init("ExoToken", "EXO");
		__ERC2981_init();
		__Pausable_init();
		__Ownable_init();
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
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

	uint private totalAmount_;
  uint private unStakableAmount;
  uint currentTime;
  uint private interest;
  uint private _maxWETHToSpend;
  uint private _perTxBuyAmount;
  address private _tokenToSell;
  address private _tokenToBuy;
  uint private _perTxWethAmount;

  struct StakerInfo{
    uint amount;
    uint date;
    uint duration;
    uint claimDate;
    uint expireDate;
    uint interest;
    bool isHardStaker;
    bool isSoftStaker;
    uint tier;
    bool candidate;
  }

  mapping(address => mapping(uint => StakerInfo)) public Staker;

  uint[] internal stakePeriod = [0, 30 seconds, 60 seconds, 90 seconds];
  uint[] internal percent = [50, 55, 60, 65, 60, 65, 70, 75, 60, 65, 70, 75, 60, 65, 70, 75];
  uint[] internal minAmount = [0, 2000, 4000, 8000];
  mapping(uint => mapping(uint => address[])) public StakeArray;

  function staking(uint _amount, uint _duration) external {
    require(_amount * decimals() <= balanceOf(msg.sender), "Not enough EXO token to stake");
    require(_duration < 4, "Duration not match");

    StakerInfo storage s = Staker[msg.sender][_duration];
    require(_amount > minAmount[s.tier], "The staking amount must be greater than the minimum amount for that tier.");
    if(_duration == 0) s.isSoftStaker = true;
    else s.isHardStaker = true;
    uint blockTimeStamp = block.timestamp;
    s.amount = _amount * decimals();
    s.date = blockTimeStamp;
    s.claimDate = blockTimeStamp;
    s.duration = stakePeriod[_duration];
    s.expireDate = s.date + stakePeriod[_duration];
    s.interest = s.tier * 4 + _duration;
    s.candidate = minAmount[s.tier] < _amount ? true : false;
    StakeArray[s.tier][_duration].push(msg.sender);

    transferFrom(msg.sender, address(this), _amount * decimals());
  }

  function _calcReward(uint _duration) internal returns(uint reward) {
    StakerInfo storage s = Staker[msg.sender][_duration];
    if(_duration == 0) currentTime = block.timestamp;
    else currentTime = block.timestamp >= s.expireDate ? s.expireDate : block.timestamp;
    uint _pastTime = currentTime - s.claimDate;
    reward = _pastTime * s.amount * percent[s.interest] / 1000 / s.duration;
  }

  function unStaking(uint _duration) public {
    StakerInfo storage s = Staker[msg.sender][_duration];
    require(s.isHardStaker || s.isSoftStaker, "You are not s.");
    require(s.expireDate < block.timestamp, "Staking period has not expired.");
    uint rewardAmount = _calcReward(_duration);
    unStakableAmount = s.amount + rewardAmount;
    
    transfer(msg.sender, unStakableAmount);
    s.isHardStaker = false;
    s.isSoftStaker = false;
    s.tier = s.candidate ? s.tier + 1 : s.tier;
    s.candidate = false;
  }

  function multiClaim(uint _tier, uint _duration) public {
    for (uint i = 0; i < StakeArray[_tier][_duration].length; i ++) {
			address staker = StakeArray[_tier][_duration][i];
			uint rewardAmount = Staker[staker][_duration].amount;
			transfer(staker, rewardAmount);
    }
  }

}