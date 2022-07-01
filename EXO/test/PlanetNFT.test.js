const { assert, expect } = require("chai");
const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;
const TransparentUpgradeableProxy = artifacts.require('TransparentUpgradeableProxy');
const ProxyAdmin = artifacts.require('ProxyAdmin');
const PlanetNFT = artifacts.require('PlanetNFT');
const PlanetNFTV2 = artifacts.require('PlanetNFTV2');

contract("PlanetNFT unit tests", async (accounts) => {
  let planetNFT, proxyAdmin, trans, planetNFTV1, planetNFTV2;
  const [minter, alice, bob, carol] = accounts;

  beforeEach(async () => {
    trans = await TransparentUpgradeableProxy.deployed();
    proxyAdmin = await ProxyAdmin.deployed();
    planetNFTV2 = await PlanetNFTV2.deployed();
    planetNFTV1 = await PlanetNFT.at(trans.address);
    await planetNFTV1.safeMint(alice, 1, { from: minter });
    await planetNFTV1.safeMint(alice, 2, { from: minter });
    await proxyAdmin.upgrade(trans.address, planetNFTV2.address);
    planetNFT = await PlanetNFTV2.at(trans.address);
  });

  describe("Token URI", () => {
    it("token uri", async () => {
      await planetNFT.setBaseURI("/ipfs/default");
      await planetNFT.setTokenURI(1, "/ipfs/1", { from: minter });

      const tokenURI1 = await planetNFT.tokenURI(1);
      const tokenURI2 = await planetNFT.tokenURI(2);
      console.log("tokenURI1", tokenURI1);
      console.log("tokenURI2", tokenURI2);
      console.log("tokenURI2", tokenURI2 === "");
    })
  })

  // describe("Deployment", () => {
  //   it("Contract has an valid address", async () => {
  //     const address = await planetNFT.address;
  //     assert.notEqual(address, 0x0);
  //     assert.notEqual(address, "");
  //     assert.notEqual(address, null);
  //     assert.notEqual(address, undefined);
  //   });
  //   it("Support name", async () => {
  //     const name = await planetNFT.name.call();
  //     assert.equal(name, "PLANET");
  //   });
  //   it("Support symbol", async () => {
  //     const symbol = await planetNFT.symbol.call();
  //     assert.equal(symbol, "PLN");
  //   });
  //   it("Support Max Limit", async () => {
  //     const maxLimit = await planetNFT.getMaxLimit();
  //     assert.equal(maxLimit, 10000);
  //   });
  //   it("Support MaxPendingMintsToProces", async () => {
  //     const maxPendingMintsToProces = await planetNFT.getMaxPendingMintsToProcess();
  //     assert.equal(maxPendingMintsToProces, 100);
  //   });
  //   it("Support oracleRandom", async () => {
  //     const oracleRandom = await planetNFT.getOracleRandom();
  //     assert.equal(oracleRandom, ZERO_ADDRESS);
  //   });
  //   describe('Initialize variables', () => {
  //     describe("Support Giveaway Address", () => {
  //       it("Minter can set giveaway Address", async () => {
  //         await planetNFT.setGiveAwayAddress(alice, { from: minter });
  //         expect(await planetNFT.getGiveAwayAddress()).to.equal(alice);
  //       });
  //       it("Others cannot set giveaway Address", async () => {
  //         await expectRevert(
  //           planetNFT.setGiveAwayAddress(alice, { from: alice }),
  //           "Ownable: caller is not the owner -- Reason given: Ownable: caller is not the owner.",
  //         );
  //       });
  //     });
  //     describe("Support TotalMintsForGiveaway", () => {
  //       it("Minter can set totalMintsForGiveaway", async () => {
  //         await planetNFT.setTotalMintsForGiveaway(10, { from: minter });
  //         assert.equal((await planetNFT.getTotalMintsForGiveaway()).toString(), '10');
  //       });
  //       it("Others cannot set totalMintsForGiveaway", async () => {
  //         await expectRevert(
  //           planetNFT.setTotalMintsForGiveaway(10, { from: alice }),
  //           "Ownable: caller is not the owner -- Reason given: Ownable: caller is not the owner.",
  //         );
  //       });
  //     });
  //   });
  // });
  // describe("Token URI", () => {
  //   before(async () => {
  //     await planetNFT.setMaxLimit(200, { from: minter });
  //     await planetNFT.setTotalMintsForGiveaway(10, { from: minter });
  //   })
  //   it("Mint `201` to alice", async () => {
  //     await planetNFT.safeMint(alice, 201, { from: minter });
  //     const ownerOf = await planetNFT.ownerOf(201);
  //     assert.equal(ownerOf, alice);
  //   });
  //   it("Sets the base token URI", async () => {
  //     await planetNFT.setBaseURI("ipfs://ExoWorlds/");
  //     let baseURI = await planetNFT.baseURI();
  //     assert.equal(baseURI, "ipfs://ExoWorlds/")
  //   });
  //   it("Get token URI", async () => {
  //     let tokenURI = await planetNFT.tokenURI(201);
  //     assert.equal(tokenURI, "ipfs://ExoWorlds/201");
  //   });
  //   it("Update base token URI", async () => {
  //     await planetNFT.setBaseURI("ipfs://ExoWorldsV2/");
  //     baseURI = await planetNFT.baseURI();
  //     assert.equal(baseURI, "ipfs://ExoWorldsV2/")
  //   });
  //   it("Get updated token URI", async () => {
  //     tokenURI = await planetNFT.tokenURI(201);
  //     assert.equal(tokenURI, "ipfs://ExoWorldsV2/201")
  //   });
  // })
  // describe("Mint batch", () => {
  //   before(async () => {
  //     await planetNFT.initTokenList({ from: minter });
  //   });
  //   it("Initialize available Tokens", async () => {
  //     assert.equal((await planetNFT.getMaxLimit()).toString(), '200');
  //   });
  //   it("Start mint batch with giveaway address", async () => {
  //     const batchAmount = new BN("4");
  //     const pendinId = new BN("0");
  //     assert.equal(await planetNFT.getMaxLimit(), 200);
  //     await planetNFT.setGiveAwayAddress(bob, { from: minter });
  //     const receipt = await planetNFT.startMintBatch(batchAmount, { from: bob });
  //     assert.equal((await planetNFT.getTotalMintsForGiveaway()).toString(), '6');
  //     expectEvent(receipt, "AddPendingMint", { minter: bob, amount: batchAmount, pendingId: pendinId });
  //     const pendingMints = await planetNFT.getPendingId();
  //     assert.equal(pendingMints.length, 4);
  //   });
  //   it("Complete mint batch with giveaway address", async () => {
  //     // Set the oracle random address
  //     await planetNFT.setOracleRandom(minter);
  //     // Complete mint batch with randomSeed 10
  //     const receipt = await planetNFT.completeMintBatch(10, { from: minter });
  //     expectEvent(receipt, "MintedWithRandomNumber", 10, { from: minter });
  //     const pendingMints = await planetNFT.getPendingId();
  //     assert.equal(pendingMints.length, 0);
  //     const tokens = await planetNFT.balanceOf(bob);
  //     assert.equal(tokens, 4);
  //   })
  // });
  // describe("Pause", () => {
  //   it("Minter can pause", async () => {
  //     const receipt = await planetNFT.pause({ from: minter });
  //     expectEvent(receipt, "Paused", { account: minter });

  //     assert.equal(await planetNFT.paused(), true);
  //   });
  //   it("Minter can unpause", async () => {
  //     const receipt = await planetNFT.unpause({ from: minter });
  //     expectEvent(receipt, "Unpaused", { account: minter });

  //     assert.equal(await planetNFT.paused(), false);
  //   });

  //   it("Cannot transfer while paused", async () => {
  //     await planetNFT.pause({ from: minter });
  //     await expectRevert(
  //       planetNFT.safeMint(alice, 0, { from: minter }),
  //       "Pausable: paused",
  //     );
  //   });
  //   it("Other accounts cannot pause", async () => {
  //     await planetNFT.unpause({ from: minter });

  //     await expectRevert(
  //       planetNFT.pause({ from: alice }),
  //       "Ownable: caller is not the owner",
  //     );
  //   });

  //   it("Other accounts cannot unpause", async () => {
  //     await planetNFT.pause({ from: minter });
  //     await expectRevert(
  //       planetNFT.unpause({ from: alice }),
  //       "Ownable: caller is not the owner",
  //     );
  //     await planetNFT.unpause({ from: minter });
  //   });
  // });
  // describe("Royalty", () => {
  //   it("Sets default royalty", async () => {
  //     await planetNFT.setDefaultRoyalty(minter, 1000, { from: minter });
  //     const { 0: receiver, 1: royalty } = await planetNFT.royaltyInfo(0, 1000);
  //     assert.equal(receiver, minter);
  //     assert.equal(royalty, 100);
  //   })
  //   it("Sets royalty for specific token `202`", async () => {
  //     await planetNFT.safeMint(alice, 202, { from: minter });
  //     await planetNFT.setTokenRoyalty(202, bob, 2000, { from: alice });
  //     const { 0: receiver, 1: royalty } = await planetNFT.royaltyInfo(202, 1000);
  //     assert.equal(receiver, bob);
  //     assert.equal(royalty, 200);
  //   })
  // })
  // describe("Burn", () => {
  //   it("Holders and others cannot burn their tokens", async () => {
  //     expectRevert(planetNFT.tokenBurn(202, { from: alice }), "Ownable: caller is not the owner");
  //     expectRevert(planetNFT.tokenBurn(202, { from: bob }), "Ownable: caller is not the owner");
  //   });
  //   it("Admin can burn their tokens", async () => {
  //     const tokenId = new BN("202");
  //     const totalSupply = await planetNFT.totalSupply();
  //     // Burn
  //     const receipt = await planetNFT.tokenBurn(tokenId, { from: minter });
  //     expectEvent(receipt, "Transfer", { from: alice, to: ZERO_ADDRESS, tokenId });
  //     // Check if burned
  //     assert.equal(await planetNFT.balanceOf(carol), 0);
  //     assert.equal(await planetNFT.totalSupply(), totalSupply - 1);

  //     // Check if removed token uri
  //     expectRevert(planetNFT.tokenURI(0), "ERC721URIStorage: URI query for nonexistent token")

  //     // Check if royalty reserted
  //     const { 0: defaultReceiver, 1: defaultRoyalty } = await planetNFT.royaltyInfo(0, 1000);
  //     assert.equal(defaultReceiver, minter);
  //     assert.equal(defaultRoyalty, 100);
  //   });
  // });
  // describe("Withdraw", () => {
  //     it("Withdraw works fine", async () => {
  //         const testPrice = new BN("200000000000000000");
  //         await planetNFT.addWhiteList(0, [alice, bob]);
  //         await planetNFT.setBlockLimit(0, 0);
  //         await planetNFT.setTierPrice(0, testPrice);
  //         const alicePrice = await planetNFT.getPrice({ from: alice });
  //         const bobPrice = await planetNFT.getPrice({ from: bob });
  //         console.log(alicePrice.toString());
  //         console.log(bobPrice.toString());
  //         await planetNFT.startMintBatch(3, { from: alice, value: web3.utils.toWei('2', 'ether') });
  //         await planetNFT.startMintBatch(3, { from: bob, value: web3.utils.toWei('2', 'ether') });
  //         await planetNFT.withdraw({ from: minter });
  //         const remainContractBalance = await web3.eth.getBalance(planetNFT.address);
  //         assert.equal(remainContractBalance, 0);
  //     });
  // })
})
