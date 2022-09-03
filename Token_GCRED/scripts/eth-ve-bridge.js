const Web3 = require('web3');

const { Framework } = require('@vechain/connex-framework');
const thor = require('web3-providers-connex')
const { Driver, SimpleNet, SimpleWallet } = require('@vechain/connex-driver')

const BridgeEth = require('../build/contracts/BridgeEth.json');
const BridgeVe = require('../build/contracts/BridgeVe.json');

const web3Eth = new Web3('https://rinkeby.infura.io/v3/0e42c582d71b4ba5a8750f688fce07da');

const main = async() => {
  const net = new SimpleNet('https://testnet.veblocks.net/')
  const wallet = new SimpleWallet();
  wallet.import(process.env.PRIVATE_KEY);
  const driver = await Driver.connect(net, wallet);
  const connex = new Framework(driver)
  const provider = new thor.ConnexProvider({ connex: connex })
  const web3Ve = new Web3(provider);
  
  const { address: admin } = web3Ve.eth.accounts.wallet.add(process.env.PRIVATE_KEY);
  
  const bridgeEth = new web3Eth.eth.Contract(
    BridgeEth.abi,
    BridgeEth.networks['4'].address
  );
  const bridgeVe = new web3Ve.eth.Contract(
    BridgeVe.abi,
    BridgeVe.networks['5777'].address
  );
  
  
  bridgeEth.events.Transfer(
    {fromBlock: 0, step: 0}
  )
  .on('data', async event => {
    const { from, to, amount, date, nonce } = event.returnValues;
  
    const tx = await bridgeVe.methods.mint(to, amount, nonce);
    console.log(tx, 'tx')
    const [gasPrice, gasCost] = await Promise.all([
      web3Ve.eth.getGasPrice(),
      tx.estimateGas({from: admin}),
    ]);
  
    const data = tx.encodeABI();
    const txData = {
      from: admin,
      to: bridgeBsc.options.address,
      data,
      gas: gasCost,
      gasPrice
    };
    const receipt = await web3Ve.eth.sendTransaction(txData);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
    console.log(`
      Processed transfer:
      - from ${from} 
      - to ${to} 
      - amount ${amount} tokens
      - date ${date}
    `);
  });
}


main()