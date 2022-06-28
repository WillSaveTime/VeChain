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
	// constructor() initializer {}

	// function initialize() public initializer {
	// 	__ERC20_init("ExoToken", "EXO");
	// 	__ERC2981_init();
	// 	__Pausable_init();
	// 	__Ownable_init();
	// }

  address public admin;

  constructor() {
    admin = msg.sender;
  }

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
  uint public votesCounter = 0;
  uint public curVoteCnt = 0;
  uint[] minAmount;
  uint[] stakePeriod;
  uint[] percent;

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

  mapping(address => mapping(uint => StakerInfo)) public stakerInfo;
  mapping(uint => mapping(uint => address[])) public StakeArray;
  mapping(address => uint) public tierStatus;

  Vote[] public vote_array;

  event Stake(address indexed _from, uint _amount, uint timestamp);
  event Claim(address indexed _to, uint _amount, uint timestamp);
  event UnStake(address indexed _from, uint _amount, uint timestamp);
  event addVote(string subject, uint start, uint end, uint timestamp);

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
    stakePeriod = [0, 30 days, 60 days, 90 days];
    return stakePeriod;
  }

  function array_percent() 
    internal 
    returns(uint[] memory) 
  {
    percent = [50, 55, 60, 65, 60, 65, 70, 75, 60, 65, 70, 75, 60, 65, 70, 75];
    return percent;
  }

  function transfer(address to, uint256 amount) 
    public 
    virtual 
    override 
    returns (bool) 
  {
    address owner = _msgSender();
    
    if(tierStatus[msg.sender] > 0) {
      uint[] memory min = array_minAmount();
      uint ExoBalance = balanceOf(msg.sender);
      uint remainBalance = ExoBalance - amount;
      if(remainBalance < min[tierStatus[msg.sender]] * _decimals) tierStatus[msg.sender] -= 1;
    }

    _transfer(owner, to, amount);
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
    require(_amount > min[tierStatus[msg.sender]], "The staking amount must be greater than the minimum amount for that tier.");
    if(_duration == 0) staker.isSoftStaker = true;
    else staker.isHardStaker = true;
    blockTimeStamp = block.timestamp;
    staker.amount = _amount * _decimals;
    staker.startDate = blockTimeStamp;
    staker.expireDate = blockTimeStamp + period[_duration];
    staker.duration = period[_duration];
    staker.interest = tierStatus[msg.sender] * 4 + _duration;
    staker.candidate = _amount > min[tierStatus[msg.sender] + 1] ? true : false;
    StakeArray[tierStatus[msg.sender]][_duration].push(msg.sender);

    emit Stake(msg.sender, _amount, block.timestamp);

    transfer(address(this), _amount * _decimals);
  }

  function _calcReward(address _address, uint _duration) 
    internal 
    returns(uint reward) 
  {
    StakerInfo storage staker = stakerInfo[_address][_duration];
    uint[] memory getPercent = array_percent();
    reward = staker.amount * getPercent[staker.interest] / staker.duration / 365000;
  }

  function unStaking(address _address, uint _duration) 
    private 
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
    blockTimeStamp = block.timestamp;
    for (uint i = 0; i < 4; i ++) { //tier
      if(StakeArray[i][_duration].length > 0) {
        for (uint j = 0; j < StakeArray[i][_duration].length; j ++) { //duration
          address stakerAddr = StakeArray[i][_duration][j];
          StakerInfo memory staker = stakerInfo[stakerAddr][_duration];
          if(staker.expireDate > blockTimeStamp){
            StakeArray[i][_duration].push(stakerAddr); 
            if(staker.interest != 0) {
              uint rewardAmount = _calcReward(stakerAddr, _duration);
              transfer(stakerAddr, rewardAmount);
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

  function get_list(uint _voteID, uint _listID) external view returns(string memory, uint) {
    Vote storage tmp_vote = vote_array[_voteID];
    string memory tmp_list = tmp_vote.lists[_listID].title;
    uint tmp_cnt = tmp_vote.lists[_listID].voteCnt;
    return (tmp_list, tmp_cnt);
  }

  function addCnt(uint _voteID, uint _listID) external returns(bool) {
    require(_voteID < votesCounter, "Not valid Vote ID");
    Vote storage tmp_vote = vote_array[_voteID];
    require(_listID < tmp_vote.lists.length, "Not valid List ID");
    uint tier = tierStatus[msg.sender];
    uint balance = balanceOf(msg.sender);
    uint voteValue = (tier * (tier + 1) / 2) * balance;
    tmp_vote.lists[_listID].voteCnt += voteValue;
    return true;
  }

  
  function createVote(string calldata _subject, string[] calldata _list, uint _startDate, uint _endDate) external onlyOwner {
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

  function get_votes() external view returns(Vote[] memory) {
    require(votesCounter > 0, "Vote Empty");
    Vote[] memory allVotes = new Vote[](votesCounter);
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = vote_array[i];
      allVotes[i] = tmp_vote;
    }
    return allVotes;
  }

  
  function get_curVotes() external view returns(Vote[] memory) {
    require(votesCounter > 0, "Vote Empty");
    Vote[] memory currentVotes = new Vote[](votesCounter);
    uint j = 0;
    for(uint i = 0; i < votesCounter; i ++) {
      Vote storage tmp_vote = vote_array[i];
      if (tmp_vote.startDate < block.timestamp && tmp_vote.endDate > block.timestamp) {
        currentVotes[j++] = tmp_vote;
      }
    }
    return currentVotes;
  }

  function get_futVotes() external view returns(Vote[] memory) {
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