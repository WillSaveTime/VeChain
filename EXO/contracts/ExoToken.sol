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
import "./GcredToken.sol";

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
  event Claim(address indexed _to, uint timestamp);
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
  uint public stakerCnt;
  uint private unStakableAmount;
  uint private blockTimeStamp;
  uint private interest;
  uint private reward_from_FN = 1E26;
  uint private totalRewardAmount;
  bool private isHardStaker;
  bool private isSoftStaker;
  bool public claimFlag;
  uint private nextClaimTime;
  uint[] stakePeriod;
  uint[] minAmount;
  uint[] percent;
  uint[] gcred;
  uint[] percentFN;
  uint constant _decimals = 1E18;
  uint constant _maxReward = 35E26;

  struct StakerInfo{
    address owner;
    uint amount;
    uint startDate;
    uint expireDate;
    uint duration;
    uint interest;
    bool isHardStaker;
    bool isSoftStaker;
    bool candidate;
    uint latestClaim;
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

  StakerInfo[][4][4] public _stakerInfo;
  List[] private _list_;

  /**
  * @notice Get Tier Status
  * @dev Get User's status address according to his address (0:Default, 1, 2, 3)
  * input: address
  */
  mapping(address => uint) public tierStatus;
  mapping(uint => Vote) public mapVote;
  mapping(address => bool) private voteFlag;

  function _minAmount() 
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
    stakePeriod = [0, 10 minutes, 20 minutes, 30 minutes];
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
    percentFN = [0, 0, 0, 0, 30, 60, 85, 115, 40, 70, 95, 125, 50, 80, 105, 145];
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
      uint[] memory min = _minAmount();
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
    require(_amount <= balanceOf(msg.sender), "Not enough EXO token to stake");
    require(_duration < 4, "Duration not match");

    if(msg.sender == FNwallet) {
      reward_from_FN = _amount.mul(75).div(1000).div(365);
    } else {
      uint[] memory min = _minAmount();
      uint[] memory period = _arrayPeriod();
      blockTimeStamp = block.timestamp;

      _stakerInfo[tierStatus[msg.sender]][_duration].push(
        StakerInfo(
          msg.sender,
          _amount,
          blockTimeStamp,
          blockTimeStamp.add(period[_duration]),
          _duration,
          tierStatus[msg.sender].mul(4).add(_duration),
          isHardStaker,
          isSoftStaker,
          _amount > min[tierStatus[msg.sender] + 1] ? true : false,
          block.timestamp
      ));
      stakerCnt ++;

    }
    
    transfer(address(this), _amount);
    emit Stake(msg.sender, _amount, block.timestamp);
  }

  function allStakers() 
    public 
    view 
    whenNotPaused
    returns(StakerInfo[] memory) 
  {
    require(stakerCnt > 0, "Nobody staked");
    uint _idx;
    StakerInfo[] memory _allStakers = new StakerInfo[](stakerCnt);
    for(uint i = 0; i < 4 ; i ++) {
      for(uint j =  0; j < 4; j ++) {
        uint len = _stakerInfo[i][j].length;
        for(uint k = 0; k < len; k ++) {
          _allStakers[_idx] = _stakerInfo[i][j][k];
          _idx ++;
        }
      }
    }
    return _allStakers;
  }

  function getStakerInfo(address _address) 
    external 
    view 
    whenNotPaused
    returns(StakerInfo[] memory) 
  {
    require(stakerCnt > 0, "Nobody staked");
    uint cnt_;
    for(uint i = 0; i < 4 ; i ++) { // tier
      for(uint j =  0; j < 4; j ++) { // duration
        uint len = _stakerInfo[i][j].length;
        for(uint k = 0; k < len; k ++) { // index
          if(_stakerInfo[i][j][k].owner == _address) {
            cnt_ ++;
          }
        }
      }
    }

    StakerInfo[] memory _currentStaker = new StakerInfo[](cnt_);
    uint idx = 0;
    for(uint i = 0; i < 4 ; i ++) { // tier
      for(uint j =  0; j < 4; j ++) { // duration
        uint len = _stakerInfo[i][j].length;
        for(uint k = 0; k < len; k ++) { // index
          if(_stakerInfo[i][j][k].owner == _address) {
            _currentStaker[idx] = _stakerInfo[i][j][k];
            idx ++;
          }
        }
      }
    }
    return _currentStaker;
  }

  function multiClaim() 
   public 
   onlyOwner
   whenNotPaused
  {
    require(stakerCnt > 0, "Nobody staked");
    if(claimFlag) {
      require(nextClaimTime >= block.timestamp, "Not started multi Claim");
    }
    uint[] memory getPercent = _arrayPercent();
    uint[] memory percentForFn = _percentOfFN();
    uint[] memory getGcredAmount = _gcredAmount();
    for(uint i = 0; i < 4 ; i ++) { // tier
      for(uint j =  0; j < 4; j ++) { // duration
        uint len = _stakerInfo[i][j].length;
        if(len > 0) {
          uint idx = i.mul(4).add(j);
          uint FN_reward = reward_from_FN.mul(percentForFn[idx]).div(len).div(1000);
          for(uint k = 0; k < _stakerInfo[i][j].length; k ++) { // index
            StakerInfo memory tmp_staker = _stakerInfo[i][j][k];

            if(block.timestamp - tmp_staker.latestClaim > 1 days) {
              if(tmp_staker.expireDate > block.timestamp) {

                uint reward = tmp_staker.amount * getPercent[tmp_staker.interest].div(365000);
                uint gcredReward = getGcredAmount[tmp_staker.interest].div(365000);
                mint(tmp_staker.owner, reward);
                mint(tmp_staker.owner, FN_reward);
                IGcredToken(GCRED).mint(tmp_staker.owner, gcredReward);
                tmp_staker.latestClaim = block.timestamp;
                emit Claim(tmp_staker.owner, block.timestamp);

              } else {

                // delete tmp_staker;
                _stakerInfo[i][j][k] = _stakerInfo[i][j][len-1];
                _stakerInfo[i][j].pop();

                _transfer(address(this), tmp_staker.owner, tmp_staker.amount);
                emit UnStake(tmp_staker.owner, tmp_staker.amount, block.timestamp);
              }
              nextClaimTime = block.timestamp + 1 days;
              claimFlag = true;
            }
          }
        }
      }
    }
  }

  function _multiClaim(uint _tier, uint _duration) 
   public 
   whenNotPaused
   returns(uint, uint, uint)
  {
    require(stakerCnt > 0, "Nobody staked");
    uint[] memory percentForFn = _percentOfFN();
    uint _FN_reward;
    uint len;
    uint len1;
    len = _stakerInfo[_tier].length;
    if(len > 0) {
      len1 = _stakerInfo[_tier][_duration].length;
      if(len1 > 0) {
        uint idx = _tier * 4 + _duration + 5;
        _FN_reward = reward_from_FN.mul(percentForFn[idx]).div(len1).div(1000);
      }
    }
    return(len, len1, _FN_reward);
  }

  function getList(uint _voteID, uint _listID) external view returns(string memory, uint) {
    Vote storage tmp_vote = mapVote[_voteID];
    string memory tmp_list = tmp_vote.lists[_listID].title;
    uint tmp_cnt = tmp_vote.lists[_listID].voteCnt;
    return (tmp_list, tmp_cnt);
  }

  function holderVote(uint _voteID, uint _listID) 
    external 
    whenNotPaused
    returns(bool) 
  {
    require(voteFlag[msg.sender], "Already voted");
    require(_voteID < votesCounter, "Not valid Vote ID");
    require(balanceOf(msg.sender) > 0, "No EXO holder");
    Vote storage tmp_vote = mapVote[_voteID];
    require(tmp_vote.endDate > block.timestamp, "Already expired");
    require(_listID < tmp_vote.lists.length, "Not valid List ID");
    uint tier = tierStatus[msg.sender];
    uint balance = balanceOf(msg.sender);
    uint voteValue = (tier.mul(tier + 1).div(2)).mul(balance);
    tmp_vote.lists[_listID].voteCnt += voteValue;
    voteFlag[msg.sender] = true;
    return true;
  }

  
  function createNewVote(string calldata _subject, string[] calldata _list, uint _startDate, uint _endDate) 
    external 
    onlyOwner 
    whenNotPaused
  {
    require(_startDate > block.timestamp, "Invalid Start Date");
    require(_startDate < _endDate, "Invalid Start Date or End Date");
    Vote storage tmp_vote = mapVote[votesCounter];
    tmp_vote.idx = votesCounter;
    tmp_vote.subject = _subject;
    tmp_vote.startDate = _startDate;
    tmp_vote.endDate = _endDate;
    tmp_vote.listCnt = _list.length;
    for(uint i = 0; i < _list.length; i ++) {
      tmp_vote.lists.push(List(_list[i], 0));
    }

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
      Vote storage tmp_vote = mapVote[i];
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
    uint cntC;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = mapVote[i];
      if (tmp_vote.startDate < block.timestamp && tmp_vote.endDate > block.timestamp) cntC ++;
    }
    Vote[] memory _currentVotes = new Vote[](cntC);
    uint j = 0;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = mapVote[i];
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
    uint cntF;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = mapVote[i];
      if (tmp_vote.startDate > block.timestamp) cntF ++;
    }
    Vote[] memory futVotes = new Vote[](cntF);
    uint j = 0;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = mapVote[i];
      if (tmp_vote.startDate > block.timestamp) {
        futVotes[j++] = tmp_vote;
      }
    }
    return futVotes;
  }

}