require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");

const { solidity } = require('ethereum-waffle');
require('chai').use(solidity);

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.11",
  networks: {
    hardhat: {
      chainId: 1,
      initialBaseFeePerGas: '50000000000'
    }
  }
};
