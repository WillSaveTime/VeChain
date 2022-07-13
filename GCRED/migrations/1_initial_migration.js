// migrations/3_deploy_upgradeable_box.js
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const TokenEth = artifacts.require('TokenEth');
// const TokenVe = artifacts.require('TokenVe');
const BridgeEth = artifacts.require('BridgeEth');
// const BridgeVe = artifacts.require('BridgeVe');

const _md_wallet = '0x138532955EE01A5DAf9800aa57a6Ae2cDD81d572';
const _dao_wallet = '0x138532955EE01A5DAf9800aa57a6Ae2cDD81d572';

module.exports = async function (deployer, network, addresses) {

  if(network === 'rinkeby') {
    await deployProxy(TokenEth, [], {deployer});
    const tokenEth = await TokenEth.deployed();
    await tokenEth.mint(addresses[0], 1000);
    await deployer.deploy(BridgeEth, tokenEth.address);
    const bridgeEth = await BridgeEth.deployed();
    await tokenEth.bridgeUpdateAdmin(bridgeEth.address);
  }
  
  // if(network === 'veTest') {
  //   await deployer.deploy(TokenVe);
  //   const tokenVe = await TokenVe.deployed();
  //   await deployer.deploy(ProxyAdmin);
  //   const proxyAdmin = await ProxyAdmin.deployed();
  //   await deployer.deploy(TransparentUpgradeableProxy, tokenVe.address, proxyAdmin.address, []);
  //   const trans = await TransparentUpgradeableProxy.deployed();
  //   const proxyGcred = await TokenVe.at(trans.address);
  //   await proxyGcred.initialize();
    
  //   // await tokenVe.mint(addresses[0], 1000);
  //   await deployer.deploy(BridgeVe, trans.address);
  //   const bridgeVe = await BridgeVe.deployed();
  //   // await tokenVe.bridgeUpdateAdmin(bridgeVe.address);
  // }
};