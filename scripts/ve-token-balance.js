const { Framework } = require('@vechain/connex-framework');
const Web3 = require('web3');
const thor = require('web3-providers-connex')
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')

const TokenVe = require('../build/contracts/TokenVe.json');
const TransparentUpgradeableProxy = require('../build/contracts/TransparentUpgradeableProxy.json');

require('dotenv').config();

module.exports = async done => {
  const net = new SimpleNet('https://testnet.veblocks.net/')
  const wallet = new SimpleWallet();
  wallet.import(process.env.PRIVATE_KEY);
  const driver = await Driver.connect(net, wallet);
  const connex = new Framework(driver)
  const provider = new thor.ConnexProvider({ connex: connex })
  const web3Ve = new Web3(provider);

  const [sender, _] = await web3.eth.getAccounts();
  const tokenVe = new web3Ve.eth.Contract(
    TokenVe.abi,
    TransparentUpgradeableProxy.networks['5777'].address
  );
  const balance = await tokenVe.methods.balanceOf(sender).call()
  console.log(balance);
  done();
}
