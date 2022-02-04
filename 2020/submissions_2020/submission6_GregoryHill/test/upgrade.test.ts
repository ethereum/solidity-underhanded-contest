import { ethers } from "@nomiclabs/buidler";
import { Signer } from "ethers";
import chai from "chai";
import { solidity } from "ethereum-waffle";

import { ProxyFactory } from "../typechain/ProxyFactory";
import { AccountsFactory } from "../typechain/AccountsFactory";
import { GoodMathFactory } from "../typechain/GoodMathFactory";
import { BadMathFactory } from "../typechain/BadMathFactory";
import { Create2Factory } from "../typechain/Create2Factory";
import { RegistryFactory } from "../typechain/RegistryFactory";

// hardcoded to ensure bytecode doesn't change
import RegistryArtifact from "../contracts/Registry.json";

chai.use(solidity);
const { expect } = chai;

describe("Upgrade", () => {
  let signers: Signer[];

  beforeEach(async () => {
    signers = await ethers.signers();
  });

  it("should deploy contracts", async () => {
    const signer = signers[0];
    const address = await signer.getAddress();

    const create2Factory = new Create2Factory(signer);
    const create2 = await create2Factory.deploy();
    // deploy registry at predicted address
    await create2.deploy(0, Buffer.alloc(32), RegistryArtifact.bytecode);

    const goodMathFactory = new GoodMathFactory(signer);
    const goodMath = await goodMathFactory.deploy();

    const registry = RegistryFactory.connect(
      "0xe7748b80eE98483c177b7a4Aa041b57b70AfE6F4",
      signer
    );
    // point registry to `GoodMath`
    await registry.set(goodMath.address);

    const proxyFactory = new ProxyFactory(signer);
    const proxy = await proxyFactory.deploy();

    // link proxy instead of library
    const accountsFactory = new AccountsFactory(
      { __$1e69b7c934b982fb20a88bb82f9f911a54$__: proxy.address },
      signer
    );
    const accounts = await accountsFactory.deploy();

    // account should be credited
    await accounts.mint(address, 100);
    expect((await accounts.balanceOf(address)).toNumber()).to.eq(100);

    // replace library with `BadMath`
    const badMathFactory = new BadMathFactory(signer);
    const badMath = await badMathFactory.deploy();
    await registry.set(badMath.address);

    // account should be debited
    await accounts.mint(address, 100);
    expect((await accounts.balanceOf(address)).toNumber()).to.eq(0);
  });
});
