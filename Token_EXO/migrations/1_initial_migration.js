// migrations/3_deploy_upgradeable_box.js
const { deployProxy, upgradeProxy  } = require('@openzeppelin/truffle-upgrades');
// const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
// const ProxyAdmin = artifacts.require('ProxyAdmin');
// const TokenEth = artifacts.require('TokenEth');
// const TokenVe = artifacts.require('TokenVe');
// const BridgeEth = artifacts.require('BridgeEth');
// const BridgeVe = artifacts.require('BridgeVe');
const LABMONSTER = artifacts.require('LabMonster')
const SLABS = artifacts.require('SLABS')

module.exports = async function (deployer, network, addresses) {

  // if(network === 'rinkeby') {
  //   await deployProxy(TokenEth, [], {deployer});
  //   const tokenEth = await TokenEth.deployed();
  //   await deployer.deploy(BridgeEth, tokenEth.address);
  //   const bridgeEth = await BridgeEth.deployed();
  //   await tokenEth.bridgeUpdateAdmin(bridgeEth.address);

  //   // const instance = await upgradeProxy("0x9412941B3b0c5bF6351311f10fff84036C7DCba9", TokenEth, { deployer });
  //   // await deployer.deploy(TokenEth);
  //   // const tokenVe = await TokenEth.deployed();
  // }
  
  // if(network === 'veTest') {
  //   await deployer.deploy(TokenVe);
  //   const tokenVe = await TokenVe.deployed();
  //   await deployer.deploy(ProxyAdmin);
  //   const proxyAdmin = await ProxyAdmin.deployed();
  //   await deployer.deploy(TransparentUpgradeableProxy, tokenVe.address, proxyAdmin.address, []);
  //   const trans = await TransparentUpgradeableProxy.deployed();
  //   const proxyExo = await TokenVe.at(trans.address);
  //   await proxyExo.initialize();
    
  //   await deployer.deploy(BridgeVe, trans.address);
  //   const bridgeVe = await BridgeVe.deployed();
  // }

  if(network === 'mumbai') {
    deployer.deploy(LABMONSTER)
    const monster = await LABMONSTER.deployed();
    deployer.deploy(SLABS)
    const slabs = await SLABS.deployed()

  }
};
