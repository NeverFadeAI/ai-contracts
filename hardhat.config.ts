import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv'
import 'hardhat-deploy'
dotenv.config()

const deployer = process.env.DEPLOY_PRIVATE_KEY || '0x' + '11'.repeat(32)
const governance = process.env.GOVERNANCE_PRIVATE_KEY || '0x' + '11'.repeat(32)
const TESTNET_BLOCK_EXPLORER_KEY = process.env.TESTNET_BLOCK_EXPLORER_KEY || '';
const MAINNET_BLOCK_EXPLORER_KEY = process.env.MAINNET_BLOCK_EXPLORER_KEY || '';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.20',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      gas: 16000000,
    },
    linea_testnet: {
      chainId: 59140,
      url: process.env.LINEA_TEST_RPC_URL || '',
      accounts: [deployer, governance],
      gasPrice: 2000000000,
      gas: 2000000,
    },
    linea_mainnet: {
      chainId: 59144,
      url: process.env.LINEA_RPC_URL || '',
      accounts: [deployer, governance],
      gasPrice: 2000000000,
      gas: 2000000,
    },
  },
  paths: {
    deploy: './deploy',
    deployments: './deployments',
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    governance: {
      default: 1,
    },
    tomosign: {
      default: 2,
    }
  },
  etherscan: {
    apiKey: {
      linea_testnet: TESTNET_BLOCK_EXPLORER_KEY,
      linea_mainnet: MAINNET_BLOCK_EXPLORER_KEY
    },
    customChains: [
      {
        network: "linea_testnet",
        chainId: 59140,
        urls: {
          apiURL: "https://api-testnet.lineascan.build/api",
          browserURL: "https://goerli.lineascan.build/address"
        }
      },
      {
        network: "linea_mainnet",
        chainId: 59144,
        urls: {
          apiURL: "https://api.lineascan.build/api",
          browserURL: "https://lineascan.build/"
        }
      },
    ]
  },
};

export default config;