const Migrations = artifacts.require("Migrations");
const { deployProxy, upgradeProxy  } = require('@openzeppelin/truffle-upgrades');
const TokenEth = artifacts.require('TokenEth');

module.exports = function (network, deployer) {
    deployer.deploy(Migrations);
    if(network === 'rinkeby') {
        const _tokenEth = await deployProxy(TokenEth, { deployer });
    }
};
