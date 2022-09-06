const { assert, expect } = require("chai");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const Bridge = artifacts.require("Bridge")

contract("Bridge Test", async(accounts) => {
  beforeEach(async () => {
    const EXO = await deployProxy(EXOToken, [], { accounts });
    const bridgeEXO = await Bridge.new(proxyEXO.address);
    await proxyEXO.grantRole(BRIDGE_ROLE, bridgeEXO.address);
    await proxyEXO.setStakingReward(proxyStaking.address);

  })

  describe("mint", () => {
    it("transfer already processed", async () => {

    })
  })

  describe("burn", () => {
    
  })
})