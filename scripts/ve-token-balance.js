const { Framework } = require('@vechain/connex-framework');
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')
const { abi } = require('thor-devkit')

const {contractABI} = require('./abi')
const ADDRESS = "0x8081D09E642f9659bec52b160770d788494855fC"

require('dotenv').config();

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
  console.log(testMethod.call)
  await testMethod.call('0x68e64e74841f761CF6f1181Ae522C09ab0f6Cd6F').then(output=>{
    baseuri = output.decoded[0];
    console.log(output)
  });
  done();
}
