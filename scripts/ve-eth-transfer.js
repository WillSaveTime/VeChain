const { Framework } = require('@vechain/connex-framework');
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')
const { abi } = require('thor-devkit')

const {contractABI} = require('./abi')
const {bridgeABI} = require('./bridgeAbi')
const ADDRESS = "0x07d05404853fAc4dD62c103943511BDc953558fb"

require('dotenv').config();

module.exports = async done => {
  const net = new SimpleNet('https://testnet.veblocks.net/')
  const wallet = new SimpleWallet();
  wallet.import(process.env.PRIVATE_KEY);
  const driver = await Driver.connect(net, wallet);
  const connex = new Framework(driver)
  const accForMP = connex.thor.account(ADDRESS)
  const findMethodABI = (abi, method) => abi[abi.findIndex(mthd => mthd.name === method)];
  const testMethod = accForMP.method(findMethodABI(bridgeABI, "bridgeBurn"))
  console.log(testMethod)
  testMethod.transact()
    .request().then(result => {
      console.log(result);
    })
  done();
}
