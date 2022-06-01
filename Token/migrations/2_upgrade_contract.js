// migrations/3_deploy_upgradeable_box.js
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const ExoToken = artifacts.require('ExoToken');

module.exports = async function (deployer) {
  await deployer.deploy(ExoToken);
  const exoToken = await ExoToken.deployed();
  // await deployer.deploy(ProxyAdmin);
  // const proxyAdmin = await ProxyAdmin.deployed();
  // await deployer.deploy(TransparentUpgradeableProxy, exoToken.address, proxyAdmin.address, []);
  // const trans = await TransparentUpgradeableProxy.deployed();
  // const proxyExo = await ExoToken.at(trans.address);
  // await proxyExo.initialize();
};
