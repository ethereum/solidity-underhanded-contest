const { expect } = require("chai");

const BN = ethers.BigNumber;
const eth = (value) => ethers.utils.parseEther(value.toString());

const SELLER_PK = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d';
const SELLER_ADDRESS = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';

describe("happy path", function () {
  it("purchases tokens from an order", async function () {
    const [_deployer, seller, buyer, referrer] = await ethers.getSigners();
    const [initialBuyerBalance, initialSellerBalance, initialReferrerBalance] = await Promise.all([
      buyer.getBalance(), seller.getBalance(), referrer.getBalance(),
    ]);
    
    const rate = BN.from(2).pow(64); // 1:1
    const nonce = 0;
    
    const token = await ethers.getContractFactory("MockERC20").then(f => f.deploy(seller.address));
    const exchange = await ethers.getContractFactory("Exchange").then(f => f.deploy());
    expect(await token.balanceOf(seller.address)).to.equal(eth(10000));
    expect(seller.address).to.equal(SELLER_ADDRESS);

    await token.connect(seller).approve(exchange.address, eth(1000));
    
    const order = [
      referrer.address,
      token.address,
      rate,
      nonce,
      eth(1000),
      1, // OrderType.PARTIAL
    ];

    const orderHash = await exchange.getOrderHash(order);
    const { v, r, s } = new ethers.utils.SigningKey(SELLER_PK).signDigest(orderHash);

    await exchange.connect(buyer).executeOrder(order, v, r, s, { value: eth(1000) });
    
    expect(await token.balanceOf(seller.address)).to.equal(eth(9000));
    expect(await token.balanceOf(buyer.address)).to.equal(eth(1000));
    expect(await buyer.getBalance()).to.closeTo(initialBuyerBalance.sub(eth(1000)), eth(0.01));
    expect(await seller.getBalance()).to.closeTo(initialSellerBalance.add(eth(990)), eth(0.01));
    expect(await referrer.getBalance()).to.equal(initialReferrerBalance.add(eth(10)));
  });
});
