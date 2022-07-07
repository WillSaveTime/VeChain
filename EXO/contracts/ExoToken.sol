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

contract ExoToken is
	Initializable,
	ERC20Upgradeable,
	ERC20BurnableUpgradeable,
	PausableUpgradeable,
	OwnableUpgradeable,
	ERC20PermitUpgradeable,
	ERC20VotesUpgradeable
{

  event Stake(address indexed _from, uint _amount, uint timestamp);
  event Claim(address indexed _to, uint _amount, uint timestamp);
  event UnStake(address indexed _from, uint _amount, uint timestamp);
  event addVote(string subject, uint start, uint end, uint timestamp);

  using SafeMathUpgradeable for uint;
  address public bridgeAddr;
  address public GCRED;
  address public FNwallet;

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function bridgeMint(address to, uint amount) 
    public
    whenNotPaused 
  {
    require(msg.sender == bridgeAddr, 'only admin');
		_mint(to, amount);
	}

  function bridgeBurn(address owner, uint amount) 
    external 
    whenNotPaused
  {
    require(msg.sender == bridgeAddr, 'only admin');
    _burn(owner, amount);
  }

  function bridgeUpdateAdmin(address newAdmin) 
    external
    onlyOwner
    whenNotPaused 
  {
    bridgeAddr = newAdmin;
  }

  function changeGCRED(address newAddr) 
    public 
    onlyOwner 
    whenNotPaused
    returns(bool) 
  {
    GCRED = newAddr;
    return true;
  }

  function changeFNwallet(address newAddr)
    public
    onlyOwner
    whenNotPaused
    returns(bool)
  {
    FNwallet = newAddr;
    return true;
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

  uint public votesCounter;
  uint private unStakableAmount;
  uint private blockTimeStamp;
  uint private interest;
  uint private reward_from_FN;
  uint private totalRewardAmount;
  uint[] stakePeriod;
  uint[] minAmount;
  uint[] percent;
  uint[] gcred;
  uint[] percentFN;
  uint constant _decimals = 1E18;
  uint constant _maxReward = 35E25;

  struct StakerInfo{
    uint amount;
    uint startDate;
    uint duration;
    uint expireDate;
    uint interest;
    bool isHardStaker;
    bool isSoftStaker;
    bool candidate;
  }

  struct List{
    string title;
    uint voteCnt; 
  }

  struct Vote{
    uint idx;
    string subject;
    uint startDate;
    uint endDate;
    List[] lists;
    uint listCnt;
  }

  Vote[] public vote_array;

  mapping(address => mapping(uint => StakerInfo)) private stakerInfo;
  mapping(uint => mapping(uint => address[])) private StakeArray;
  mapping(address => uint) public tierStatus;

  function _arrayMinAmount() 
    internal
    returns(uint[] memory) 
  {
    minAmount = [0, 2000, 4000, 8000];
    return minAmount;
  }

  function _arrayPeriod() 
    internal 
    returns(uint[] memory) 
  {
    stakePeriod = [0, 30 days, 60 days, 90 days];
    return stakePeriod;
  }

  function _arrayPercent() 
    internal 
    returns(uint[] memory) 
  {
    percent = [50, 55, 60, 65, 60, 65, 70, 75, 60, 65, 70, 75, 60, 65, 70, 75];
    return percent;
  }

  function _gcredAmount() 
    internal 
    returns(uint[] memory) 
  {
    gcred = [0, 0, 0, 242, 0, 0, 266, 354, 0, 0, 293, 390, 0, 0, 322, 426];
    return gcred;
  }

  function _percentOfFN()
    internal
    returns(uint[] memory)
  {
    percentFN = [30, 60, 85, 115, 40, 70, 95, 125, 50, 80, 105, 145];
    return percentFN;
  }

  function transfer(address to, uint256 amount) 
    public 
    virtual 
    override 
    whenNotPaused
    returns (bool) 
  {
    address owner = _msgSender();
    
    if(tierStatus[msg.sender] > 0) {
      uint[] memory min = _arrayMinAmount();
      uint ExoBalance = balanceOf(msg.sender);
      uint remainBalance = ExoBalance.sub(amount);
      if(remainBalance < min[tierStatus[msg.sender]].mul(_decimals)) tierStatus[msg.sender] -= 1;
    }

    _transfer(owner, to, amount);
    return true;
  }

  function staking(uint _amount, uint _duration) 
    external 
    whenNotPaused
  {
    require(_amount * _decimals <= balanceOf(msg.sender), "Not enough EXO token to stake");
    require(_duration < 4, "Duration not match");

    if(msg.sender == FNwallet) {
      reward_from_FN = _amount.mul(75).div(1000).div(365);
      
    } else {
      StakerInfo storage staker = stakerInfo[msg.sender][_duration];
      uint[] memory min = _arrayMinAmount();
      uint[] memory period = _arrayPeriod();
      require(_amount > min[tierStatus[msg.sender]], "The staking amount must be greater than the minimum amount for that tier.");
      if(_duration == 0) staker.isSoftStaker = true;
      else staker.isHardStaker = true;
      blockTimeStamp = block.timestamp;
      staker.amount = _amount.mul(_decimals);
      staker.startDate = blockTimeStamp;
      staker.expireDate = blockTimeStamp.add(period[_duration]);
      staker.duration = period[_duration];
      staker.interest = tierStatus[msg.sender].mul(4).add(_duration);
      staker.candidate = _amount > min[tierStatus[msg.sender] + 1] ? true : false;
      StakeArray[tierStatus[msg.sender]][_duration].push(msg.sender);
    }

    emit Stake(msg.sender, _amount, block.timestamp);
    transfer(address(this), _amount.mul(_decimals));
  }

  function _calcReward(address _address, uint _duration) 
    internal 
    returns(uint reward, uint __gcredAmount) 
  {
    StakerInfo storage staker = stakerInfo[_address][_duration];
    uint[] memory getPercent = _arrayPercent();
    reward = staker.amount * getPercent[staker.interest].div(staker.duration).div(365000);
    uint[] memory getGcredAmount = _gcredAmount();
    __gcredAmount = getGcredAmount[staker.interest];
  }

  function unStaking(address _address, uint _duration) 
    internal 
  {
    StakerInfo storage staker = stakerInfo[_address][_duration];
    unStakableAmount = staker.amount;
    
    transfer(_address, unStakableAmount);
    tierStatus[_address] = staker.candidate ? tierStatus[_address] + 1 : tierStatus[_address];
    reSetInfo(_address, _duration);
    emit UnStake(_address, unStakableAmount, block.timestamp);
  }

  function multiClaim(uint _duration) 
    public 
  {
    require(_duration < 4, "Duration not match");
    require(totalRewardAmount > _maxReward, "Total reward amount exceeds!");
    blockTimeStamp = block.timestamp;
    for (uint i = 0; i < 4; i ++) { //tier
      if(StakeArray[i][_duration].length > 0) {
        uint stakers = StakeArray[i][_duration].length;
        uint[] memory getPercent = _percentOfFN();
        if(i > 0) {
          uint fn_reward = reward_from_FN.mul(getPercent[(i + 4) * _duration - 4]).div(stakers).div(10);
          for (uint j = 0; j < StakeArray[i][_duration].length; j ++) { //duration
            address stakerAddr = StakeArray[i][_duration][j];
            transfer(stakerAddr, fn_reward);
          }
        }
        for (uint j = 0; j < StakeArray[i][_duration].length; j ++) { //duration
          address stakerAddr = StakeArray[i][_duration][j];
          StakerInfo memory staker = stakerInfo[stakerAddr][_duration];
          if(staker.expireDate > blockTimeStamp){
            StakeArray[i][_duration].push(stakerAddr); 
            if(staker.interest != 0) {
              (uint rewardAmount, uint gcredAmount) = _calcReward(stakerAddr, _duration);
              totalRewardAmount += rewardAmount;
              mint(stakerAddr, rewardAmount);
              IERC20Upgradeable(GCRED).transfer(stakerAddr, gcredAmount);
              emit Claim(stakerAddr, rewardAmount, block.timestamp);
            }
          } else {
              unStaking(stakerAddr, _duration);
          }
        }
      }
    }
  }

  function reSetInfo(address _address, uint _duration) internal {
    StakerInfo storage staker = stakerInfo[_address][_duration];
    delete staker.amount;
    delete staker.startDate;
    delete staker.duration;
    delete staker.expireDate;
    delete staker.interest;
    delete staker.isHardStaker;
    delete staker.isSoftStaker;
    delete staker.candidate;
  }

  function getList(uint _voteID, uint _listID) external view returns(string memory, uint) {
    Vote storage tmp_vote = vote_array[_voteID];
    string memory tmp_list = tmp_vote.lists[_listID].title;
    uint tmp_cnt = tmp_vote.lists[_listID].voteCnt;
    return (tmp_list, tmp_cnt);
  }

  function holderVote(uint _voteID, uint _listID) 
    external 
    whenNotPaused
    returns(bool) 
  {
    require(_voteID < votesCounter, "Not valid Vote ID");
    Vote storage tmp_vote = vote_array[_voteID];
    require(_listID < tmp_vote.lists.length, "Not valid List ID");
    uint tier = tierStatus[msg.sender];
    uint balance = balanceOf(msg.sender);
    uint voteValue = (tier.mul(tier + 1).div(2)).mul(balance);
    tmp_vote.lists[_listID].voteCnt += voteValue;
    return true;
  }

  
  function createNewVote(string calldata _subject, string[] calldata _list, uint _startDate, uint _endDate) 
    external 
    whenNotPaused
    onlyOwner 
  {
    Vote storage tmp_vote = vote_array[votesCounter];
    tmp_vote.idx = votesCounter;
    tmp_vote.subject = _subject;
    tmp_vote.startDate = _startDate;
    tmp_vote.endDate = _endDate;
    tmp_vote.listCnt = _list.length;
    for(uint i = 0; i < _list.length; i ++) {
      tmp_vote.lists.push(List(_list[i], 0));
    }
    vote_array.push(tmp_vote);
    votesCounter ++;

    emit addVote(_subject, _startDate, _endDate, block.timestamp);
  }

  function allVotes() 
    external 
    view 
    whenNotPaused
    returns(Vote[] memory) 
  {
    require(votesCounter > 0, "Vote Empty");
    Vote[] memory _allVotes = new Vote[](votesCounter);
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = vote_array[i];
      _allVotes[i] = tmp_vote;
    }
    return _allVotes;
  }

  
  function currentVotes() 
    external 
    view 
    whenNotPaused
    returns(Vote[] memory) 
  {
    require(votesCounter > 0, "Vote Empty");
    Vote[] memory _currentVotes = new Vote[](votesCounter);
    uint j = 0;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = vote_array[i];
      if (tmp_vote.startDate < block.timestamp && tmp_vote.endDate > block.timestamp) {
        _currentVotes[j++] = tmp_vote;
      }
    }
    return _currentVotes;
  }

  function futureVotes() 
    external 
    view 
    whenNotPaused
    returns(Vote[] memory) 
  {
    require(votesCounter > 0, "Vote Empty");
    Vote[] memory futVotes = new Vote[](votesCounter);
    uint j = 0;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = vote_array[i];
      if (tmp_vote.startDate > block.timestamp) {
        futVotes[j++] = tmp_vote;
      }
    }
    return futVotes;
  }
}