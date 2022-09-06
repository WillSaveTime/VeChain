const { assert, expect } = require("chai");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { writeContracts } = require("truffle");
const EXOToken = artifacts.require("EXOToken")

contract("EXO test", async() => {
  beforeEach(async () => {
    const EXO = await deployProxy(EXOToken, [], { deployer });
  })
})