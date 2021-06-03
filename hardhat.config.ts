// plug-ins
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-web3"
import "@nomiclabs/hardhat-waffle"
import "hardhat-typechain"

import "@nomiclabs/hardhat-etherscan";

import { HardhatUserConfig } from "hardhat/types";


const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: "0.8.0", settings: {} },
    ]
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: 12000000,
      allowUnlimitedContractSize: true,
      blockGasLimit: 12000000,
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  },
  etherscan: {
    // API key for https://etherscan.io/
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  // typechain: {
  //   outDir: "types",
  // },
};
export default config;