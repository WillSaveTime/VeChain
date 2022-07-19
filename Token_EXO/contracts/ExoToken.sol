// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IGcredToken {
	function mintForReward(address to, uint256 amount) external;
}

contract ExoToken is
	Initializable,
	ERC20Upgradeable,
	ERC20BurnableUpgradeable,
	PausableUpgradeable,
	OwnableUpgradeable
{

  event Stake(address indexed _from, uint _amount, uint timestamp);
  event Claim(address indexed _to, uint timestamp);
  event ClaimGCRED(address indexed _to, uint _amount, uint timestamp);
  event ClaimFN(address indexed _to, uint _amount, uint timestamp);
  event UnStake(address indexed _from, uint _amount, uint timestamp);
  event addVote(string subject, uint start, uint end, uint timestamp);

  using SafeMathUpgradeable for uint;
  address public bridgeAddr;
  address public GCRED;
  address public FNwallet;

  IGcredToken GcredToken;

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
    GcredToken = IGcredToken(newAddr);
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
	) internal override(ERC20Upgradeable) {
		super._afterTokenTransfer(from, to, amount);
	}

	function _mint(address to, uint amount)
		internal
		override(ERC20Upgradeable)
	{
		super._mint(to, amount);
	}

	function _burn(address account, uint amount)
		internal
		override(ERC20Upgradeable)
	{
		super._burn(account, amount);
	}

  uint public votesCounter;
  uint public stakerCnt;
  uint private unStakableAmount;
  uint private blockTimeStamp;
  uint private interest;
  uint private reward_from_FN;
  uint private totalRewardAmount;
  bool private isHardStaker;
  bool private isSoftStaker;
  bool public claimFlag;
  uint public prevClaimTime;
  uint[] stakePeriod;
  uint[] minAmount;
  uint[] percent;
  uint[] gcred;
  uint[16] percentFN;
  uint constant _decimals = 1E18;
  uint constant _maxReward = 35E26;
  uint constant _claimDelay = 3 minutes;
  // uint constant _reward_from_FN = 1E28 ;
  uint constant _reward_from_FN = 205479E18;
  struct StakerInfo{
    address owner;
    uint amount;
    uint startDate;
    uint expireDate;
    uint duration;
    uint interest;
    bool isHardStaker;
    bool isSoftStaker;
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

  StakerInfo[] public _stakerInfo;
  List[] private _list_;

  /**
  * @notice Get Tier Status
  * @dev Get User's status address according to his address (0:Default, 1, 2, 3)
  * tierStatus: status of user
  * tierCandidate: true if user is available for update
  * stakingCnt: count of staking done by specific user
  * voteFlag: true if user voted
  */
  mapping(address => uint) public tierStatus;
  mapping(address => bool) public tierCandidate;
  mapping(address => uint) public stakingCnt;
  mapping(uint => Vote) public mapVote;
  mapping(address => bool) private voteFlag;

  //Minimum Amount of Staking Required for Each Tiers
  function _minAmount() 
    internal
    returns(uint[] memory) 
  {
    minAmount = [0, 2000, 4000, 8000];
    return minAmount;
  }

  //Duration Mode Array
  function _arrayPeriod() 
    internal 
    returns(uint[] memory) 
  {
    stakePeriod = [0, 10 minutes, 20 minutes, 30 minutes];
    return stakePeriod;
  }

  //Normal EXO Reward Percent Array
  function _arrayPercent() 
    internal 
    returns(uint[] memory) 
  {
    percent = [50, 55, 60, 65, 60, 65, 70, 75, 60, 65, 70, 75, 60, 65, 70, 75];
    return percent;
  }

  //GCRED Reward Percent Array
  function _gcredAmount() 
    internal 
    returns(uint[] memory) 
  {
    gcred = [0, 0, 0, 242, 0, 0, 266, 354, 0, 0, 293, 390, 0, 0, 322, 426];
    return gcred;
  }

  //Foundation Node Reward Percent Array
  function _percentOfFN()
    internal
    returns(uint[16] memory)
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
    uint[] memory min = _minAmount();
    
    if(tierStatus[msg.sender] > 0) {
      uint ExoBalance = balanceOf(msg.sender);
      uint remainBalance = ExoBalance.sub(amount);
      if(remainBalance < min[tierStatus[msg.sender]].mul(_decimals) && stakingCnt[msg.sender]<1) tierStatus[msg.sender] -= 1;
        tierStatus[msg.sender] -= 1;
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

    uint stakingBalance;
    uint[] memory min = _minAmount();

    StakerInfo[] memory _getStakerInfo = getStakerInfo(msg.sender);
    for(uint i = 0; i < _getStakerInfo.length; i ++) {
      stakingBalance += _getStakerInfo[i].amount;
    }

    require((balanceOf(msg.sender) + stakingBalance) >= min[tierStatus[msg.sender]].mul(_decimals), "You need more EXO to stake in your tier level");

    if(msg.sender == FNwallet) {
      reward_from_FN = _amount.mul(75).div(1000).div(365);
    } else {
      uint[] memory period = _arrayPeriod();
      blockTimeStamp = block.timestamp;

      _stakerInfo.push(
        StakerInfo(
          msg.sender,
          _amount,
          blockTimeStamp,
          blockTimeStamp.add(period[_duration]),
          _duration,
          tierStatus[msg.sender].mul(4).add(_duration),
          isHardStaker,
          isSoftStaker,
          block.timestamp
      ));
      if(tierStatus[msg.sender] < 3 && min[tierStatus[msg.sender]+1].mul(_decimals) <_amount && _duration>tierStatus[msg.sender] )
        tierCandidate[msg.sender] = true;
      stakerCnt ++;
      stakingCnt[msg.sender]++;
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
    for(uint i = 0; i < _stakerInfo.length; i ++) {
      _allStakers[_idx] = _stakerInfo[i];
      _idx ++;
    }
    return _allStakers;
  }

  function getStakerInfo(address _address) 
    public 
    view 
    whenNotPaused
    returns(StakerInfo[] memory) 
  {
    require(stakerCnt > 0, "Nobody staked");
    uint len = _stakerInfo.length;

    uint cnt_;
    for(uint i = 0; i < len ; i ++) { // tier
      if(_stakerInfo[i].owner == _address) {
        cnt_ ++;
      }
    }

    StakerInfo[] memory _currentStaker = new StakerInfo[](cnt_);
    uint idx = 0;
    for(uint i = 0; i < len ; i ++) { // tier
      if(_stakerInfo[i].owner == _address) {
        _currentStaker[idx] = _stakerInfo[i];
        idx ++;
      }
    }
    return _currentStaker;
  }

  function multiClaim() 
    public 
    onlyOwner
    whenNotPaused
  {
    require(_stakerInfo.length > 0, "Nobody staked");
    if(claimFlag) {
      require(block.timestamp - prevClaimTime >= _claimDelay, "Not started new multi claim");
    }
    uint[] memory getPercent = _arrayPercent();
    uint[] memory getGcredAmount = _gcredAmount();
    uint[16] memory _reward_fn;
    for(uint i = 0; i < _stakerInfo.length; i ++) {
      address _stakerAddr = _stakerInfo[i].owner;
      uint _stakerAmount = _stakerInfo[i].amount;
      uint _idx = _stakerInfo[i].interest;
      if(_stakerInfo[i].expireDate > block.timestamp) {
        if(block.timestamp - _stakerInfo[i].latestClaim >= _claimDelay) {
          _reward_fn[_idx] += 1;
          uint _precent = getPercent[_stakerInfo[i].interest];
          uint reward = _calcReward(_stakerAmount, _precent);
          mint(_stakerAddr, reward);

          uint gcredReward = getGcredAmount[_stakerInfo[i].interest].mul(_decimals).div(1000);
          _sendGcred(_stakerAddr, gcredReward);
          _stakerInfo[i].latestClaim = block.timestamp;
          
          emit Claim(_stakerAddr, block.timestamp);
        }

      } else {
        if(_stakerInfo[i].duration>=tierStatus[_stakerAddr] && tierCandidate[_stakerAddr] ){
          if(tierStatus[_stakerAddr]<3){
            tierStatus[_stakerAddr] += 1;
          }
          tierCandidate[_stakerAddr] = false;
        }
        stakerCnt--;
        stakingCnt[_stakerAddr]--;
        uint len = _stakerInfo.length;
        _stakerInfo[i] = _stakerInfo[len-1];
        _stakerInfo.pop();
        if(i!=0)
          i--;
        _transfer(address(this), _stakerAddr, _stakerAmount);
        emit UnStake(_stakerAddr, _stakerAmount, block.timestamp);
      }

    }
    _rewardFromFn(_reward_fn);
    claimFlag = true;
    prevClaimTime = block.timestamp;
  }

  function _calcReward(uint _amount, uint _percent) internal pure returns(uint){
    return _amount.mul(_percent).div(365000);
  }

  function _rewardFromFn(uint[16] memory _reward_fn) internal{
    uint[16] memory percentOfFn = _percentOfFN();
    uint[16] memory _rewardAmountFn;
    for(uint i = 0; i < percentOfFn.length; i ++) {
      if(_reward_fn[i] == 0) {
        _rewardAmountFn[i] = 0;
      } else {
        _rewardAmountFn[i] = _reward_from_FN.mul(percentOfFn[i]).div(_reward_fn[i]).div(1000);
      }
    }
    for(uint i = 0; i < _stakerInfo.length; i ++) {
      uint _rewardAmount = _rewardAmountFn[_stakerInfo[i].interest];
      if(_rewardAmount != 0) {
        mint(_stakerInfo[i].owner, _rewardAmount);
        emit ClaimFN(_stakerInfo[i].owner, _rewardAmount, block.timestamp);
      }
    }

  }

  function _sendGcred(address _address, uint _amount) internal {
    GcredToken.mintForReward(_address, _amount);
    emit ClaimGCRED(_address, _amount, block.timestamp);
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
    require(!voteFlag[msg.sender], "Already voted");
    require(_voteID < votesCounter, "Not valid Vote ID");
    require(balanceOf(msg.sender) > 0, "No EXO holder");
    Vote storage tmp_vote = mapVote[_voteID];
    require(tmp_vote.endDate > block.timestamp, "Already expired");
    require(tmp_vote.startDate <= block.timestamp, "Not started yet");
    require(_listID < tmp_vote.lists.length, "Not valid List ID");
    uint tier = tierStatus[msg.sender];
    uint balance = balanceOf(msg.sender);
    uint voteValue = (1 + (tier.mul(tier + 1).div(2)).mul(25).div(100)).mul(balance);
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