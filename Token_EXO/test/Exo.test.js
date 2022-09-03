const { assert, expect } = require("chai");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const TokenEth = artifacts.require('TokenEth');
const BridgeEth = artifacts.require('BridgeEth');

contract("EXO unit test", async(accounts, deployer) => {
  const [alice, bob] = accounts;

  beforeEach(async() => {
    await deployProxy(TokenEth, [], {deployer});
    const tokenEth = await TokenEth.deployed();
    await deployer.deploy(BridgeEth, tokenEth.address);
    const bridgeEth = await BridgeEth.deployed();
    await tokenEth.bridgeUpdateAdmin(bridgeEth.address);
  })

  describe("transfer", () => {
    
  })
})