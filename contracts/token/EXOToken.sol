// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interface/IStakingReward.sol";
import "../interface/IEXOToken.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EXOToken is
    Initializable,
    IEXOToken,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    uint256 constant decimal = 1e18;

    address private stakingReward;

    // Bridge contract address that can mint or burn
    address private bridge;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("EXO Token", "EXO");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        uint256 _totalSupply = 10000000000 * (10 ** decimal);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @inheritdoc IEXOToken
    function bridgeMint(address to, uint256 amount)
        external
        override
        whenNotPaused
        onlyRole(BRIDGE_ROLE)
    {
        _mint(to, amount);
    }

    /// @inheritdoc IEXOToken
    function bridgeBurn(address owner, uint256 amount)
        external
        override
        whenNotPaused
        onlyRole(BRIDGE_ROLE)
    {
        _burn(owner, amount);
    }

    /// @inheritdoc IEXOToken
    function setBridge(address _bridge)
        external
        override
        onlyRole(BRIDGE_ROLE)
    {
        _revokeRole(BRIDGE_ROLE, bridge);
        bridge = _bridge;
        _grantRole(BRIDGE_ROLE, bridge);
    }

    /// @inheritdoc IEXOToken
    function setStakingReward(address _staking)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, stakingReward);
        stakingReward = _staking;
        _grantRole(MINTER_ROLE, stakingReward);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._afterTokenTransfer(from, to, amount);

        address user = _msgSender();
        uint8 tier = IStakingReward(stakingReward).getTier(user);
        uint256[] memory stakingIndex = IStakingReward(stakingReward)
            .getStakingIndex(user);
        // Check if should downgrade user's tier
        if (tier > 0) {
            uint24[4] memory minimumAmount = IStakingReward(stakingReward)
                .getTierMinAmount();
            uint256 balance = balanceOf(user);
            if (
                balance < uint256(minimumAmount[tier]) * decimal &&
                stakingIndex.length < 1
            ) IStakingReward(stakingReward).setTier(user, tier - 1);
        }
    }
}
