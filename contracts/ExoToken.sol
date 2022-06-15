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
  uint private interest;
  uint private _maxWETHToSpend;
  uint private _perTxBuyAmount;
  address private _tokenToSell;
  address private _tokenToBuy;
  uint private _perTxWethAmount;
  uint constant _decimals = 1E18;
  uint private blockTimeStamp;
  uint private currentTime;
  uint[] minAmount;
  uint[] stakePeriod;
  uint[] percent;

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

  mapping(address => mapping(uint => StakerInfo)) public stakerInfo;

  mapping(uint => mapping(uint => address[])) public StakeArray;
  mapping(address => uint) public tierStatus;

  event Stake(address indexed _from, uint _amount);
  event Claim(address indexed _to, uint _amount);
  event ExoTransfer(address indexed _from, address indexed _to, uint _amount);

  function array_minAmount() 
    private 
    returns(uint[] memory) 
  {
    minAmount = [0, 2000, 4000, 8000];
    return minAmount;
  }

  function array_period() 
    private 
    returns(uint[] memory) 
  {
    stakePeriod = [0, 30 seconds, 60 seconds, 90 seconds];
    return stakePeriod;
  }

  function array_percent() 
    internal 
    returns(uint[] memory) 
  {
    percent = [50, 55, 60, 65, 60, 65, 70, 75, 60, 65, 70, 75, 60, 65, 70, 75];
    return percent;
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    uint ExoBalance = balanceOf(msg.sender);
    
    uint[] memory min = array_minAmount();
    if(ExoBalance < min[tierStatus[msg.sender]]) tierStatus[msg.sender] -= 1;
    _transfer(owner, to, amount);
    emit ExoTransfer(owner, to, amount);
    return true;
  }

  function staking(uint _amount, uint _duration) 
    external 
  {
    require(_amount * _decimals <= balanceOf(msg.sender), "Not enough EXO token to stake");
    require(_duration < 4, "Duration not match");

    StakerInfo storage staker = stakerInfo[msg.sender][_duration];
    uint[] memory min = array_minAmount();
    uint[] memory period = array_period();
    require(_amount > min[staker.tier], "The staking amount must be greater than the minimum amount for that tier.");
    if(_duration == 0) staker.isSoftStaker = true;
    else staker.isHardStaker = true;
    blockTimeStamp = block.timestamp;
    staker.amount = _amount * _decimals;
    staker.date = blockTimeStamp;
    staker.claimDate = blockTimeStamp;
    staker.expireDate = blockTimeStamp + period[_duration];
    staker.duration = period[_duration];
    staker.interest = staker.tier * 4 + _duration;
    staker.candidate = minAmount[staker.tier] < _amount ? true : false;
    StakeArray[staker.tier][_duration].push(msg.sender);
    tierStatus[msg.sender] = staker.tier;

    transfer(address(this), _amount * _decimals);

    emit Stake(msg.sender, _amount);

  }

  function _calcReward(address _address, uint _duration) 
    internal 
    returns(uint reward) 
  {
    StakerInfo storage staker = stakerInfo[_address][_duration];
    uint[] memory getPercent = array_percent();
    currentTime = block.timestamp;
    if(_duration == 0) currentTime = currentTime;
    else currentTime = currentTime >= staker.expireDate ? staker.expireDate : currentTime;
    uint _pastTime = currentTime - staker.claimDate;
    reward = _pastTime * staker.amount * getPercent[staker.interest] / 1000 / staker.duration;
  }

  function unStaking(address _address, uint _duration) 
    private 
    returns(address unstakeraddress, bool status)
  {
    StakerInfo storage staker = stakerInfo[_address][_duration];
    // require(staker.isHardStaker || staker.isSoftStaker, "You are not staker.");
    // require(staker.expireDate < block.timestamp, "Staking period has not expired.");
    // uint rewardAmount = _calcReward(_duration);

    unStakableAmount = staker.amount;
    
    transfer(_address, unStakableAmount);
    staker.isHardStaker = false;
    staker.isSoftStaker = false;
    staker.tier = staker.candidate ? staker.tier + 1 : staker.tier;
    staker.candidate = false;
    unstakeraddress = _address;
    status = true;
  }

  function multiClaim(uint _duration) 
    public 
  {
    require(_duration < 4, "Duration not match");
    blockTimeStamp = block.timestamp;
    for (uint i = 0; i < 4; i ++) {
      if(StakeArray[i][_duration].length > 0) {
        for (uint j = 0; j < StakeArray[i][_duration].length; j ++) {
          address stakerAddr = StakeArray[i][_duration][j];
          StakerInfo memory staker = stakerInfo[stakerAddr][_duration];
          if(staker.expireDate > blockTimeStamp){
            StakeArray[i][_duration].push(stakerAddr); 
            if(staker.interest != 0) {
              uint rewardAmount = staker.amount;
              super.transfer(stakerAddr, rewardAmount);
              emit Claim(stakerAddr, rewardAmount);
            }
          } else {
              unStaking(stakerAddr, _duration);
          }
        }
      }
    }
  }
}