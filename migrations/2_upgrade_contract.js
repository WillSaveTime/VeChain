// migrations/3_deploy_upgradeable_box.js
const { deployProxy, upgradeProxy  } = require('@openzeppelin/truffle-upgrades');

const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const TokenEth = artifacts.require('TokenEth');
const TokenVe = artifacts.require('TokenVe');
const BridgeEth = artifacts.require('BridgeEth');
const BridgeVe = artifacts.require('BridgeVe');

module.exports = async function (deployer, network, addresses) {
  if(network === 'rinkeby') {
    const _tokenEth = await deployProxy(TokenEth, { deployer });

    // await deployer.deploy(TokenEth);
    // const tokenEth = await TokenEth.deployed();
    // await deployer.deploy(ProxyAdmin);
    // const proxyAdmin = await ProxyAdmin.deployed();
    // await deployer.deploy(TransparentUpgradeableProxy, tokenEth.address, proxyAdmin.address, []);
    // const trans = await TransparentUpgradeableProxy.deployed();
    // const proxyExo = await TokenEth.at(trans.address);
    // await proxyExo.initialize();

    // await tokenEth.mint(addresses[0], 1000);
    // await deployer.deploy(BridgeEth, trans.address);
    // const bridgeEth = await BridgeEth.deployed();
    // await tokenEth.bridgeUpdateAdmin(bridgeEth.address);

  }
  
  if(network === 'testnet') {
    await deployer.deploy(TokenVe);
    const tokenVe = await TokenVe.deployed();
    await deployer.deploy(ProxyAdmin);
    const proxyAdmin = await ProxyAdmin.deployed();
    await deployer.deploy(TransparentUpgradeableProxy, tokenVe.address, proxyAdmin.address, []);
    const trans = await TransparentUpgradeableProxy.deployed();
    const proxyExo = await TokenVe.at(trans.address);
    // await proxyExo.initialize();
    
    await TokenVe.mint(addresses[0], 1000);
    await deployer.deploy(BridgeVe, trans.address);
    const bridgeVe = await BridgeVe.deployed();
    await tokenVe.bridgeUpdateAdmin(bridgeVe.address);
  }
};
