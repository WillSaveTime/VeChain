// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interface/IStakingReward.sol";
import "../interface/IEXOToken.sol";
import "../interface/IGCREDToken.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract StakingReward is
    Initializable,
    IStakingReward,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant EXO_ROLE = keccak256("EXO_ROLE");

    uint256 constant decimal = 1e18;
    uint256 constant MAX_REWRAD = 35e26;
    /*------------------Test Only------------------*/
    uint256 constant CLAIM_DELAY = 1 days;
    // uint256 constant FN_REWARD = 0x205479E18;
    /*---------------------------------------------*/
    // Counter for staking
    uint256 public stakingCounter;
    // EXO token address
    address public EXO_ADDRESS;
    // GCRED token address
    address public GCRED_ADDRESS;
    // Foundation Node wallet which is releasing EXO to prevent inflation
    address public FOUNDATION_NODE;
    // Reward amount from FN wallet
    uint256 private _FN_REWARD;
    // Last staking timestamp
    uint256 private latestStakingTime;
    // Last claimed time
    uint256 public latestClaimTime;
    // All staking infors
    StakingInfo[] public stakingInfos;
    // Tier of the user; Tier 0 ~ 3
    mapping(address => uint8) public tier;
    // Whether holder can upgrade tier status
    mapping(address => bool) public tierCandidate;
    // Mapping from address to staking index array
    mapping(address => uint256[]) public stakingIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _EXO_ADDRESS, address _GCRED_ADDRESS)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(EXO_ROLE, _EXO_ADDRESS);

        EXO_ADDRESS = _EXO_ADDRESS;
        GCRED_ADDRESS = _GCRED_ADDRESS;
    }

    /// @inheritdoc	IStakingReward
    function stake(uint256 _amount, uint8 _duration)
        external
        override
        whenNotPaused
    {
        address holder = _msgSender();
        require(
            _amount <= IERC20Upgradeable(EXO_ADDRESS).balanceOf(holder),
            "StakingReward: Not enough EXO token to stake"
        );
        require(_duration < 4, "StakingReward: Duration does not match");

        if (holder == FOUNDATION_NODE) {
            // Calculate reward amount from Foudation Node wallet
            _FN_REWARD = (_amount * 75) / 1000 / 365;
        } else {
            uint24[4] memory minAmount = _getTierMinAmount();
            uint24[4] memory period = _getStakingPeriod();
            latestStakingTime = block.timestamp;
            uint8 _tier = tier[holder] * 4 + _duration;

            stakingInfos.push(
                StakingInfo(
                    holder,
                    _amount,
                    latestStakingTime,
                    latestStakingTime + uint256(period[_duration]),
                    _duration,
                    block.timestamp,
                    _tier
                )
            );
            // Check user can upgrade tier
            if (
                tier[holder] < 3 &&
                _amount >= uint256(minAmount[tier[holder] + 1]) &&
                _duration > tier[holder]
            ) tierCandidate[holder] = true;
            stakingIndex[holder].push(stakingCounter);
            stakingCounter++;
        }

        IERC20Upgradeable(EXO_ADDRESS).transferFrom(
            holder,
            address(this),
            _amount
        );
        emit Stake(holder, _amount, block.timestamp);
    }

    function claimBatch() external onlyRole(OWNER_ROLE) whenNotPaused {
        require(stakingInfos.length > 0, "StakingReward: Nobody staked");
        require(
            block.timestamp - latestClaimTime >= CLAIM_DELAY,
            "StakingReward: Not started new multi claim"
        );
        // Staking holder counter in each `interestRate`
        uint256[16] memory interestHolderCounter;

        for (uint256 i = 0; i < stakingInfos.length; i++) {
            address stakingHolder = stakingInfos[i].holder;
            uint256 stakingAmount = stakingInfos[i].amount;
            uint256 interestRate = stakingInfos[i].interestRate;
            // Calculate reward EXO amount
            uint256 REWARD_APR = _getEXORewardAPR(
                stakingInfos[i].interestRate
            );
            uint256 reward = _calcReward(stakingAmount, REWARD_APR);
            // Calculate GCRED daily reward
            uint256 GCRED_REWARD = (uint256(
                _getGCREDReturn(stakingInfos[i].interestRate)
            ) * decimal) / 1000;
            if (block.timestamp < stakingInfos[i].expireDate) {
                // Claim reward every day
                if (
                    block.timestamp - stakingInfos[i].latestClaimDate >=
                    CLAIM_DELAY
                ) {
                    // Count
                    interestHolderCounter[interestRate] += 1;
                    
                    // Mint reward to staking holder
                    IEXOToken(EXO_ADDRESS).mint(stakingHolder, reward);
                    // send GCRED to holder
                    _sendGCRED(stakingHolder, GCRED_REWARD);
                    // Update latest claimed date
                    stakingInfos[i].latestClaimDate = block.timestamp;

                    emit Claim(stakingHolder, block.timestamp);
                }
            } else {
                /* The staking date is expired */
                // Upgrade holder's tier
                if (
                    stakingInfos[i].duration >= tier[stakingHolder] &&
                    tierCandidate[stakingHolder]
                ) {
                    if (tier[stakingHolder] < 3) {
                        tier[stakingHolder] += 1;
                    }
                    tierCandidate[stakingHolder] = false;
                }
                // Decrease staking counter
                stakingCounter--;
                // Update holder's staking index array
                uint256[] storage holderStakingIndex = stakingIndex[
                    stakingHolder
                ];
                holderStakingIndex[i] = holderStakingIndex[
                    holderStakingIndex.length - 1
                ];
                holderStakingIndex.pop();
                // Update total staking array
                uint256 totalLength = stakingInfos.length;
                stakingInfos[i] = stakingInfos[totalLength - 1];
                stakingInfos.pop();
                if (i != 0) i--;

                // Mint reward to staking holder
                IEXOToken(EXO_ADDRESS).mint(stakingHolder, reward);
                // send GCRED to holder
                _sendGCRED(stakingHolder, GCRED_REWARD);
                // Return staked EXO to holder
                IERC20Upgradeable(EXO_ADDRESS).transfer(
                    stakingHolder,
                    stakingAmount
                );
                emit UnStake(stakingHolder, stakingAmount, block.timestamp);
            }
        }
        _getRewardFromFN(interestHolderCounter);
        latestClaimTime = block.timestamp;
    }

    /// @inheritdoc IStakingReward
    function setEXOAddress(address _EXO_ADDRESS)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        EXO_ADDRESS = _EXO_ADDRESS;

        emit EXOAddressUpdated(EXO_ADDRESS);
    }

    /// @inheritdoc IStakingReward
    function setGCREDAddress(address _GCRED_ADDRESS)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        GCRED_ADDRESS = _GCRED_ADDRESS;

        emit GCREDAddressUpdated(GCRED_ADDRESS);
    }

    function setFNAddress(address _FOUNDATION_NODE)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        FOUNDATION_NODE = _FOUNDATION_NODE;

        emit FoundationNodeUpdated(FOUNDATION_NODE);
    }

    function setTier(address _holder, uint8 _tier)
        external
        override
        onlyRole(EXO_ROLE)
    {
        tier[_holder] = _tier;
    }

    function getStakingInfos(address _holder)
        external
        view
        returns (StakingInfo[] memory)
    {
        require(stakingCounter > 0, "EXO: Nobody staked");
        uint256 len = stakingIndex[_holder].length;
        StakingInfo[] memory _currentStaker = new StakingInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            _currentStaker[i] = stakingInfos[stakingIndex[_holder][i]];
        }

        return _currentStaker;
    }

    function getStakingIndex(address _holder)
        external
        view
        returns (uint256[] memory)
    {
        return stakingIndex[_holder];
    }

    /// @inheritdoc IStakingReward
    function getTier(address _user) external view returns (uint8) {
        return tier[_user];
    }

    /// @dev Minimum EXO amount in tier
    function getTierMinAmount() external pure returns (uint24[4] memory) {
        uint24[4] memory tierMinimumAmount = [0, 200_000, 400_0000, 800_0000];
        return tierMinimumAmount;
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function _getRewardFromFN(uint256[16] memory _interestHolderCounter)
        internal
    {
        uint8[16] memory FN_REWARD_PERCENT = _getFNRewardPercent();
        uint256[16] memory _rewardAmountFn;
        for (uint256 i = 0; i < FN_REWARD_PERCENT.length; i++) {
            if (_interestHolderCounter[i] == 0) {
                _rewardAmountFn[i] = 0;
            } else {
                _rewardAmountFn[i] =
                    (_FN_REWARD * uint256(FN_REWARD_PERCENT[i])) /
                    _interestHolderCounter[i] /
                    1000;
            }
        }
        for (uint256 i = 0; i < stakingInfos.length; i++) {
            uint256 _rewardAmount = _rewardAmountFn[
                stakingInfos[i].interestRate
            ];
            if (_rewardAmount != 0) {
                IEXOToken(EXO_ADDRESS).mint(
                    stakingInfos[i].holder,
                    _rewardAmount
                );
                emit ClaimFN(
                    stakingInfos[i].holder,
                    _rewardAmount,
                    block.timestamp
                );
            }
        }
    }

    /// @dev Staking period
    function _getStakingPeriod() internal pure returns (uint24[4] memory) {
        uint24[4] memory stakingPeriod = [0, 30 days, 60 days, 90 days];
        return stakingPeriod;
    }

    /// @dev Minimum EXO amount in tier
    function _getTierMinAmount() internal pure returns (uint24[4] memory) {
        uint24[4] memory tierMinimumAmount = [0, 200_000, 400_0000, 800_0000];
        return tierMinimumAmount;
    }

    /// @dev EXO Staking reward APR
    function _getEXORewardAPR(uint8 _interestRate)
        internal
        pure
        returns (uint8)
    {
        uint8[16] memory EXO_REWARD_APR = [
            50,
            55,
            60,
            65,
            60,
            65,
            70,
            75,
            60,
            65,
            70,
            75,
            60,
            65,
            70,
            75
        ];
        return EXO_REWARD_APR[_interestRate];
    }

    /// @dev Foundation Node Reward Percent Array
    function _getFNRewardPercent() internal pure returns (uint8[16] memory) {
        uint8[16] memory FN_REWARD_PERCENT = [
            0,
            0,
            0,
            0,
            30,
            60,
            85,
            115,
            40,
            70,
            95,
            125,
            50,
            80,
            105,
            145
        ];
        return FN_REWARD_PERCENT;
    }

    /// @dev GCRED reward per day
    function _getGCREDReturn(uint8 _interest) internal pure returns (uint16) {
        uint16[16] memory GCRED_RETURN = [
            0,
            0,
            0,
            242,
            0,
            0,
            266,
            354,
            0,
            0,
            293,
            390,
            0,
            0,
            322,
            426
        ];
        return GCRED_RETURN[_interest];
    }

    function _sendGCRED(address _address, uint256 _amount) internal {
        IGCREDToken(GCRED_ADDRESS).mintForReward(_address, _amount);
        emit ClaimGCRED(_address, _amount, block.timestamp);
    }

    function _calcReward(uint256 _amount, uint256 _percent)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _percent) / 365000;
    }
}
