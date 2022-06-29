const { Framework } = require('@vechain/connex-framework');
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')
const { abi } = require('thor-devkit')

const {contractABI} = require('./abi')
const ADDRESS = "0x82077C6bF254BeA2aEE44E3fF2b5682580B9B9a3"

const TokenVe = artifacts.require('./TokenVe.sol');

module.exports = async done => {
  const net = new SimpleNet('https://testnet.veblocks.net/')
  const wallet = new SimpleWallet();
  wallet.import(process.env.PRIVATE_KEY);
  const driver = await Driver.connect(net, wallet);
  const connex = new Framework(driver)
  const accForMP = connex.thor.account(ADDRESS)
  const findMethodABI = (abi, method) => abi[abi.findIndex(mthd => mthd.name === method)];
  const testMethod = accForMP.method(findMethodABI(contractABI, "balanceOf"))
  console.log(testMethod)
  await testMethod.call('68e64e74841f761cf6f1181ae522c09ab0f6cd6f').then(output=>{
    baseuri = output.decoded[0];
    console.log(baseuri)
  });

  // const [recipient, _] = await web3.eth.getAccounts();
  // const tokenVe = await TokenVe.deployed();
  // const balance = await tokenVe.balanceOf(recipient);
  // console.log(balance.toString());
  done();
}
