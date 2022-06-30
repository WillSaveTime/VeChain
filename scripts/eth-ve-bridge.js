const Web3 = require('web3');

const { Framework } = require('@vechain/connex-framework');
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')

const {bridgeABI} = require('./bridgeAbi')
const ADDRESS = "0xbE25bFD67eb51A4B1C21d41A099c33Ee750F522E"

const BridgeEth = require('../build/contracts/BridgeEth.json');

const web3Eth = new Web3('Infura Rinkeby  url');
const adminPrivKey = '';
const { address: admin } = web3Bsc.eth.accounts.wallet.add(adminPrivKey);

const bridgeEth = new web3Eth.eth.Contract(
  BridgeEth.abi,
  BridgeEth.networks['4'].address
);

const net = new SimpleNet('https://testnet.veblocks.net/')
const wallet = new SimpleWallet();
wallet.import(process.env.PRIVATE_KEY);
const driver = await Driver.connect(net, wallet);
const connex = new Framework(driver)
const accForMP = connex.thor.account(ADDRESS)
const findMethodABI = (abi, method) => abi[abi.findIndex(mthd => mthd.name === method)];
const testMethod = accForMP.method(findMethodABI(bridgeABI, "burn"))

bridgeEth.events.Transfer(
  {fromBlock: 0, step: 0}
)
.on('data', async event => {
  const { from, to, amount, date, nonce } = event.returnValues;

  const tx = await testMethod.transact(to, amount).request();

  const data = tx.encodeABI();
  const txData = {
    from: admin,
    to: bridgeBsc.options.address,
    data,
    gas: gasCost,
    gasPrice
  };
  const receipt = await web3Bsc.eth.sendTransaction(txData);
  console.log(`Transaction hash: ${receipt.transactionHash}`);
  console.log(`
    Processed transfer:
    - from ${from} 
    - to ${to} 
    - amount ${amount} tokens
    - date ${date}
  `);
});
