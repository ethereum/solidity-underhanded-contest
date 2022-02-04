import { usePlugin } from "@nomiclabs/buidler/config";

usePlugin("@nomiclabs/buidler-ganache");
usePlugin("@nomiclabs/buidler-waffle");
usePlugin("buidler-typechain");

const config = {
  defaultNetwork: "buidlerevm",
  solc: {
    version: "0.7.0",
    optimizer: { enabled: true, runs: 500 },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
  },
  typechain: {
    outDir: "typechain",
    target: "ethers",
  },
  networks: {
    buidlerevm: {},
  },
};

export default config;
