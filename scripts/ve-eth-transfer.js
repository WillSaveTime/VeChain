const { Framework } = require('@vechain/connex-framework');
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')

const {bridgeABI} = require('./bridgeAbi')
const ADDRESS = "0xbE25bFD67eb51A4B1C21d41A099c33Ee750F522E"

require('dotenv').config();

module.exports = async done => {
  const net = new SimpleNet('https://testnet.veblocks.net/')
  const wallet = new SimpleWallet();
  wallet.import(process.env.PRIVATE_KEY);
  const driver = await Driver.connect(net, wallet);
  const connex = new Framework(driver)
  const accForMP = connex.thor.account(ADDRESS)
  const findMethodABI = (abi, method) => abi[abi.findIndex(mthd => mthd.name === method)];
  const testMethod = accForMP.method(findMethodABI(bridgeABI, "burn"))
  await testMethod.transact("0x68e64e74841f761CF6f1181Ae522C09ab0f6Cd6F", 55555555)
    .request().then(result => {
      console.log(result);
    })
  done();
}
