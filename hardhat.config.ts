import dotenv from "dotenv";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "hardhat-contract-sizer";
import "@typechain/hardhat";
import { HardhatUserConfig } from "hardhat/config";

dotenv.config();

const apiKey = process.env.ETHERSCAN_API_KEY;
const privateKey = process.env.PRIVATE_KEY;
const developmentMnemonic =
  "test test test test test test test test test test test junk";

module.exports = {
    solidity: {
      compilers: [
        {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }
      },
      {
        version: "0.4.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }        
      }
    ]
    },
    mocha: {
      timeout: '100000'
    },
    networks: {
      hardhat: {
        accounts: {
          mnemonic: developmentMnemonic,
          count: 30,
        },
        saveDeployments: true
      },
      localhost: {
        url: "http://localhost:8545",
        accounts: [privateKey],
        gas: 2100000,
        gasPrice: 8000000000,
        allowUnlimitedContractSize: true,
      },
      sepolia: {
        url: "https://1rpc.io/sepolia	",
        chainId: 11155111,
        gasPrice: 20000000000,
        accounts: [privateKey],
      },
    },
    gasReporter: {
      enabled: process.env.REPORT_GAS === "true" ? true : false,
      currency: "USD"
    },
    etherscan: {
      apiKey: apiKey,
    },
    typechain: {
      outDir: "typechain-types",
      target: "ethers-v5"
    },
    abiExporter: {
      path: './abis',
      flat: false,
      format: "json"
    },
    contractSizer: {
      alpha: true,
      runOnCompile: true,
      disambiguatePaths: false,
    }
  
}