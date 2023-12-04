import "@nomicfoundation/hardhat-foundry";
import "hardhat-contract-sizer";
import "hardhat-deploy";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",

  namedAccounts: {
    deployer: 0
  },

  networks: {
    hardhat: {},
    localhost: {},
    goerli: {
      url: process.env.GOERLI_URL || `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    arb: {
      url: process.env.ARB_URL || `https://arb.getblock.io/${process.env.GETBLOCK_KEY}/mainnet/`,
      accounts: 
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mantle: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.mantle.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },

  etherscan: {
    apiKey: {
      arb: process.env.ARBISCAN_API_KEY
    },
  },
};
