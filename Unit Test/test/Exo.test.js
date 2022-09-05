const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { describe, it } = require("node:test");

describe("TokenEth", () => {
  beforeEach(async() => {
    const TokenEth = await hre.ethers.getContractFactory("TokenEth");
    console.log("Deploying TokenEth...")
    const tokenEth = await upgrades.deployProxy(TokenEth, [])
  })

  describe("staking", () => {
    it("should enough EXO token to stake", async() => {
      await tokenEth.staking(100, 3)

      expect(await tokenEth.StakeArray)
    })
  })
})
