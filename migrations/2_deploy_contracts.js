// migrations/3_deploy_upgradeable_box.js
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const EXOToken = artifacts.require('EXOToken');
const GCREDToken = artifacts.require('GCREDToken');
const StakingReward = artifacts.require('StakingReward');
const Governance = artifacts.require('Governance');
const Bridge = artifacts.require('Bridge');

// Wallets from ganache: Test purpose only
const MD_ADDRESS = "0x88Cb518C9b3Bd85255dd82e618958f60E0cD133B";
const DAO_ADDRESS = "0xa9F0E130c8f5F7FFc83Ba4648Bdb56Fd4c0202D2";

module.exports = async function (deployer, network, addresses) {

  if (network === 'rinkeby') {
    // 1. Deploy EXO token
    const EXO = await deployProxy(EXOToken, [], { deployer });
    // 2. Deploy GCRED token
    const GCRED = await deployProxy(GCREDToken, [], { deployer });
    // 3. Deploy StakingReward contract with token addresses
    const stakingReward = await deployProxy(StakingReward, [EXO.address, GCRED.address], { deployer });
    // 4. Deploy Governance contract with EXO address and Staking address
    const governance = await deployProxy(Governance, [EXO.address, stakingReward.address], { deployer });
    // 5. Deploy 2 bridge contracts for EXO and GCRED
    const bridgeEXO = await Bridge.new(proxyEXO.address);
    const bridgeGCRED = await Bridge.new(proxyGCRED.address);

    // 6. Set Staking address and bridge address in EXO contract
    const BRIDGE_ROLE = await proxyEXO.BRIDGE_ROLE();
    await proxyEXO.grantRole(BRIDGE_ROLE, bridgeEXO.address);
    await proxyEXO.setStakingReward(proxyStaking.address);
    await proxyGCRED.grantRole(BRIDGE_ROLE, bridgeGCRED.address);
  }

  if (network === 'development') {
    // This process is for vechain only
    // 1. Deploy EXO token
    await deployer.deploy(EXOToken);
    const EXO = await EXOToken.deployed();
    const adminEXO = await ProxyAdmin.new();
    console.log(adminEXO.address);
    const transEXO = await TransparentUpgradeableProxy.new(EXO.address, adminEXO.address, []);
    const proxyEXO = await EXOToken.at(transEXO.address);
    await proxyEXO.initialize();

    // 2. Deploy GCRED token
    await deployer.deploy(GCREDToken);
    const GCRED = await GCREDToken.deployed();
    const adminGCRED = await ProxyAdmin.new();
    const transGCRED = await TransparentUpgradeableProxy.new(GCRED.address, adminGCRED.address, []);
    const proxyGCRED = await GCREDToken.at(transGCRED.address);
    await proxyGCRED.initialize(MD_ADDRESS, DAO_ADDRESS, proxyEXO.address);

    // 3. Deploy StakingReward contract with token addresses
    await deployer.deploy(StakingReward);
    const stakingReward = await StakingReward.deployed();
    const adminStaking = await ProxyAdmin.new();
    const transStaking = await TransparentUpgradeableProxy.new(stakingReward.address, adminStaking.address, []);
    const proxyStaking = await StakingReward.at(transStaking.address);
    await proxyStaking.initialize(proxyEXO.address, proxyGCRED.address);

    // 4. Deploy Governance contract with EXO address and Staking address
    await deployer.deploy(Governance);
    const governance = await Governance.deployed();
    const adminGovernance = await ProxyAdmin.new();
    const transGovernance = await TransparentUpgradeableProxy.new(governance.address, adminGovernance.address, []);
    const proxyGovernance = await Governance.at(transGovernance.address);
    await proxyGovernance.initialize(proxyEXO.address, proxyStaking.address);

    // 5. Deploy 2 bridge contracts for EXO and GCRED
    const bridgeEXO = await Bridge.new(proxyEXO.address);
    const bridgeGCRED = await Bridge.new(proxyGCRED.address);

    // 6. Set Staking address and bridge address in EXO contract
    const BRIDGE_ROLE = await proxyEXO.BRIDGE_ROLE();
    await proxyEXO.grantRole(BRIDGE_ROLE, bridgeEXO.address);
    await proxyEXO.setStakingReward(proxyStaking.address);
    await proxyGCRED.grantRole(BRIDGE_ROLE, bridgeGCRED.address);
  }
};
