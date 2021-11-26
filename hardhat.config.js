require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");


const { API_URL, API_KOVAN_URL, API_RINKEBY_URL, PRIVATE_KEY, PRIVATE_KEY_DEV } = process.env;

module.exports = {
  solidity: {
     version: "0.8.4",
     settings: {
        optimizer: {
           enabled: true,
           runs: 200
        },
     },
   },
  defaultNetwork: "hardhat",
    networks: {
       hardhat: {},
       rinkeby: {
          url: API_RINKEBY_URL,
          accounts: [`0x${PRIVATE_KEY_DEV}`]
       },
       kovan: {
        url: API_KOVAN_URL,
        accounts: [`0x${PRIVATE_KEY_DEV}`]
      },
       mainnet: {
         url: API_URL,
         accounts: [`0x${PRIVATE_KEY}`]
      }
    },
    etherscan: {
       apiKey: process.env.ETHERSCAN_API_KEY
    },
    mocha: {
      timeout: 100000
    }
 };