const { Framework } = require('@vechain/connex-framework');
import { web3, web3 } from '@openzeppelin/test-helpers/src/setup';
const thor = require('web3-providers-connex')

const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')
const { abi } = require('thor-devkit')

const {contractABI} = require('./abi')
const ADDRESS = "0xe5DCDAeE57c42A016919c2F6078E6d217dF53F50"

require('dotenv').config();

const TokenVe = artifacts.require('./TokenVe.sol');

module.exports = async done => {
  const net = new SimpleNet('https://testnet.veblocks.net/')
  const wallet = new SimpleWallet();
  wallet.import(process.env.PRIVATE_KEY);
  const driver = await Driver.connect(net, wallet);
  const connex = new Framework(driver)
  const provider = new thor.ConnexProvider({ connex: connex })
  const web3 = new web3(provider);
  console.log(web3, 'web3')

  return;
  const accForMP = connex.thor.account(ADDRESS)
  const findMethodABI = (abi, method) => abi[abi.findIndex(mthd => mthd.name === method)];
  const testMethod = accForMP.method(findMethodABI(contractABI, "balanceOf"))
  await testMethod.call('0x68e64e74841f761CF6f1181Ae522C09ab0f6Cd6F').then(output=>{
    baseuri = output.decoded[0];
    console.log(baseuri)
  });
  done();
}
