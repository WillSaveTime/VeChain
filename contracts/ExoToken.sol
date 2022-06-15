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
	) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
		super._afterTokenTransfer(from, to, amount);
	}

	function _mint(address to, uint256 amount)
		internal
		override(ERC20Upgradeable, ERC20VotesUpgradeable)
	{
		super._mint(to, amount);
	}

	function _burn(address account, uint256 amount)
		internal
		override(ERC20Upgradeable, ERC20VotesUpgradeable)
	{
		super._burn(account, amount);
	}

	uint256 private totalAmount_;
  uint256 private unStakableAmount;
  uint256 private interest;
  uint256 private _maxWETHToSpend;
  uint256 private _perTxBuyAmount;
  address private _tokenToSell;
  address private _tokenToBuy;
  uint256 private _perTxWethAmount;
  uint256 constant _decimals = 1E18;
  uint256[4] minAmount;
  uint256[4] stakePeriod;
  uint256[12] percent;

  struct StakerInfo{
    uint256 amount;
    uint256 date;
    uint256 duration;
    uint256 claimDate;
    uint256 interest;
    bool isHardStaker;
    bool isSoftStaker;
    uint256 tier;
    bool candidate;
  }

  mapping(address => mapping(uint256 => StakerInfo)) public stakerInfo;

  mapping(uint256 => mapping(uint256 => address[])) public StakeArray;

  function array_minAmount() private returns(uint256[4] memory) {
    minAmount = [0, 2000, 4000, 8000, 9000];
    return minAmount;
  }

  function array_period() private returns(uint256[4] memory) {
    stakePeriod = [0, 30 seconds, 60 seconds, 90 seconds];
    return stakePeriod;
  }

  function array_percent() internal returns(uint256[12] memory) {
    percent = [uint(50), 55, 60, 65, 60, 65, 70, 75, 60, 65, 70, 75, 60, 65, 70, 75];
    return percent;
  } 

  function staking(uint256 _amount, uint256 _duration) external {
    require(_amount * _decimals <= balanceOf(msg.sender), "Not enough EXO token to stake");
    require(_duration < 4, "Duration not match");

    StakerInfo storage staker = stakerInfo[msg.sender][_duration];
    uint256[4] memory min = array_minAmount();
    uint[4] memory period = array_period();
    require(_amount > min[staker.tier], "The staking amount must be greater than the minimum amount for that tier.");
    if(_duration == 0) staker.isSoftStaker = true;
    else staker.isHardStaker = true;
    uint256 blockTimeStamp = block.timestamp;
    staker.amount = _amount * _decimals;
    staker.date = blockTimeStamp;
    staker.claimDate = blockTimeStamp;
    staker.duration = period[_duration];
    staker.interest = staker.tier * 4 + _duration;
    staker.candidate = minAmount[staker.tier] < _amount ? true : false;
    StakeArray[staker.tier][_duration].push(msg.sender);

    transfer(msg.sender, _amount * _decimals);

  }

  function _calcReward(uint _duration) internal returns(uint reward) {
    StakerInfo storage staker = Staker[msg.sender][_duration];
    if(_duration == 0) currentTime = block.timestamp;
    else currentTime = block.timestamp >= staker.expireDate ? staker.expireDate : block.timestamp;
    uint _pastTime = currentTime - staker.claimDate;
    reward = _pastTime * staker.amount * percent[staker.interest] / 1000 / staker.duration;
  }

  function unStaking(uint _duration) public {
    StakerInfo storage staker = Staker[msg.sender][_duration];
    require(staker.isHardStaker || staker.isSoftStaker, "You are not staker.");
    require(staker.expireDate < block.timestamp, "Staking period has not expired.");
    uint rewardAmount = _calcReward(_duration);
    unStakableAmount = staker.amount + rewardAmount;
    
    transfer(msg.sender, unStakableAmount);
    staker.isHardStaker = false;
    staker.isSoftStaker = false;
    staker.tier = staker.candidate ? staker.tier + 1 : staker.tier;
    staker.candidate = false;
  }

  function multiClaim(uint _duration) public {
    for (uint i = 0; i < 4; i ++) {
      for (uint j = 0; j < StakeArray[i][_duration].length; j ++) {
        address staker = StakeArray[i][_duration][j];
        uint rewardAmount = Staker[staker][_duration].amount;
        transfer(staker, rewardAmount);
      }
    }
  }
}