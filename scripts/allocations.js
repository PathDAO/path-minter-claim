require('dotenv').config();
const addresses = [""]
const API_URL = process.env.API_URL;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/Path.sol/Path.json");
const contractAddress = "0xb3C496Ac558B9DA5DE646289315c3493B93f3221";
const nftContract = new web3.eth.Contract(contract.abi, contractAddress);
async function whitelist_add(addresses) {
  const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, 'latest'); //get latest nonce
  //the transaction
  const tx = {
    'from': PUBLIC_KEY,
    'to': contractAddress,
    'nonce': nonce,
    'gas': 500000,
    'maxPriorityFeePerGas': 1999999987,
    'data': nftContract.methods.addtoWhitelist(addresses).encodeABI()
  };


const signPromise = web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
  signPromise.then((signedTx) => {
    web3.eth.sendSignedTransaction(signedTx.rawTransaction, function(err, hash) {
      if (!err) {
        console.log("The hash of your transaction is: ", hash, "\nCheck Alchemy's Mempool to view the status of your transaction!"); 
      } else {
        console.log("Something went wrong when submitting your transaction:", err)
      }
    });
  }).catch((err) => {
    console.log("Promise failed:", err);
  });
}

whitelist_add(addresses);