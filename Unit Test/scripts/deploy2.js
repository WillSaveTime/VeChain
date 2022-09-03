// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { upgrades } = require("hardhat")

async function main() {

  const TokenEth = await hre.ethers.getContractFactory("TokenEth");
  console.log("Deploying TokenEth...")
  const tokenEth = await upgrades.deployProxy(TokenEth, [])
  console.log('token eth address', tokenEth.address)
  console.log(await upgrades.erc1967.getImplementationAddress(tokenEth.address)," getImplementationAddress")
  console.log(await upgrades.erc1967.getAdminAddress(tokenEth.address)," getAdminAddress")    

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
