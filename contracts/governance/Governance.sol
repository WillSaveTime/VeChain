// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interface/IGovernance.sol";
import "../interface/IStakingReward.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Governance is
    Initializable,
    IGovernance,
    PausableUpgradeable,
    OwnableUpgradeable
{
    // Counter for votes
    uint256 public voteCounter;
    // EXO token contract address
    address public EXO_ADDRESS;
    // Staking reward contract address
    address public STAKING_ADDRESS;

    // All registered votes
    mapping(uint256 => Vote) public registeredVotes;
    // Whether voter can vote to the specific vote->proposal
    mapping(address => mapping(uint256 => bool)) private hasVoted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _EXO_ADDRESS, address _STAKING_ADDRESS)
        public
        initializer
    {
        __Pausable_init();
        __Ownable_init();
        EXO_ADDRESS = _EXO_ADDRESS;
        STAKING_ADDRESS = _STAKING_ADDRESS;
    }

    /// @inheritdoc	IGovernance
    function createVote(
        string calldata _subject,
        uint256 _startDate,
        uint256 _endDate,
        string[] calldata _proposals
    ) external override onlyOwner whenNotPaused {
        // Validate voting period
        require(_startDate > block.timestamp, "Governance: Invalid start date");
        require(_startDate < _endDate, "Governance: Invalid end date");
        // Register a new vote
        Vote storage newVote = registeredVotes[voteCounter];
        newVote.index = voteCounter;
        newVote.subject = _subject;
        newVote.startDate = _startDate;
        newVote.endDate = _endDate;
        for (uint256 i = 0; i < _proposals.length; i++) {
            newVote.proposals.push(Proposal(_proposals[i], 0));
        }
        voteCounter++;

        emit NewVote(_subject, _startDate, _endDate, block.timestamp);
    }

    /// @inheritdoc	IGovernance
    function castVote(uint256 _voteId, uint8 _proposalId)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        address voter = _msgSender();
        // Validate vote id
        require(_voteId < voteCounter, "Governance: Not valid Vote ID");
        // Validate if EXO holder
        require(
            IERC20Upgradeable(EXO_ADDRESS).balanceOf(voter) > 0,
            "Governance: Not EXO holder"
        );
        // Check if already voted or not
        require(!hasVoted[voter][_voteId], "Governance: User already voted");
        // Register a new vote
        Vote storage vote = registeredVotes[_voteId];
        require(
            vote.endDate > block.timestamp,
            "Governance: Vote is already expired"
        );
        require(
            vote.startDate <= block.timestamp,
            "Governance: Vote is not started yet"
        );
        require(
            _proposalId < vote.proposals.length,
            "Governance: Not valid proposal id"
        );
        // Calculate vote weight using user's tier and EXO balance
        uint8 tier = IStakingReward(STAKING_ADDRESS).getTier(voter);
        uint256 balance = IERC20Upgradeable(EXO_ADDRESS).balanceOf(voter);
        uint256 voteWeight = uint256(1 + (((tier * tier + 1) / 2) * 25) / 100) *
            balance;
        vote.proposals[_proposalId].voteCount += voteWeight;
        // Set true `hasVoted` flag
        hasVoted[voter][_voteId] = true;

        emit VoteCast(voter, _voteId, voteWeight, _proposalId);

        return voteWeight;
    }

    /// @inheritdoc	IGovernance
    function setEXOAddress(address _EXO_ADDRESS) external whenNotPaused {
        EXO_ADDRESS = _EXO_ADDRESS;

        emit EXOAddressUpdated(_EXO_ADDRESS);
    }

    /// @inheritdoc	IGovernance
    function setStakingAddress(address _STAKING_ADDRESS)
        external
        whenNotPaused
    {
        STAKING_ADDRESS = _STAKING_ADDRESS;

        emit StakingAddressUpdated(STAKING_ADDRESS);
    }

    /// @inheritdoc	IGovernance
    function getAllVotes()
        external
        view
        override
        whenNotPaused
        returns (Vote[] memory)
    {
        require(voteCounter > 0, "EXO: Registered votes Empty");
        Vote[] memory allVotes = new Vote[](voteCounter);
        for (uint256 i = 0; i < voteCounter; i++) {
            Vote storage tmp_vote = registeredVotes[i];
            allVotes[i] = tmp_vote;
        }
        return allVotes;
    }

    /// @inheritdoc	IGovernance
    function getActiveVotes()
        external
        view
        override
        whenNotPaused
        returns (Vote[] memory)
    {
        require(voteCounter > 0, "EXO: Vote Empty");
        Vote[] memory activeVotes;
        uint256 j = 0;
        for (uint256 i = 0; i < voteCounter; i++) {
            Vote storage activeVote = registeredVotes[i];
            if (
                activeVote.startDate < block.timestamp &&
                activeVote.endDate > block.timestamp
            ) {
                activeVotes[j++] = activeVote;
            }
        }
        return activeVotes;
    }

    /// @inheritdoc	IGovernance
    function getFutureVotes()
        external
        view
        override
        whenNotPaused
        returns (Vote[] memory)
    {
        require(voteCounter > 0, "EXO: Vote Empty");
        Vote[] memory futureVotes;
        uint256 j = 0;
        for (uint256 i = 0; i < voteCounter; i++) {
            Vote storage tmp_vote = registeredVotes[i];
            if (tmp_vote.startDate > block.timestamp) {
                futureVotes[j++] = tmp_vote;
            }
        }
        return futureVotes;
    }

    /// @inheritdoc	IGovernance
    function getProposal(uint256 _voteId, uint256 _proposalId)
        external
        view
        override
        whenNotPaused
        returns (Proposal memory)
    {
        Vote memory targetVote = registeredVotes[_voteId];
        Proposal memory targetProposal = targetVote.proposals[_proposalId];
        return targetProposal;
    }

    /// @dev Pause contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }
}
