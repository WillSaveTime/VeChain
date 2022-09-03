const { assert, expect } = require("chai");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const TokenEth = artifacts.require('TokenEth');
const BridgeEth = artifacts.require('BridgeEth');

contract("EXO unit test", async(accounts, deployer) => {
  let trans, proxyAdmin, tokenEth;
  const [alice, bob] = accounts;

  beforeEach(async() => {
    trans = await TransparentUpgradeableProxy.deployed();
    proxyAdmin = await ProxyAdmin.deployed();
    tokenEth = await TokenEth.deployed();
    await proxyAdmin.upgrade(trans.address, tokenEth.address);
    eXO = await tokenEth.at(trans.address)
  })

  describe("staking", () => {
    it("should revert with message 'Not enought EXO token to stake'", async () => {
      await eXO.deployed();
    })
  })
})