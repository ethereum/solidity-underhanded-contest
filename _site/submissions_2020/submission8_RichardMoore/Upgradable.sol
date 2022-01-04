
interface ProxyMultisig {
    function getTargetAddress() external returns (Proxyable);
}


interface Proxyable {
    function doPublicSomething() external view returns (string memory);
}

contract SafeProxyable is Proxyable {
    function doPublicSomething() override external view returns (string memory) {
       return "Free hugs! (the good guys)";
    }
}

contract DangerousProxyable is Proxyable {
    function doPublicSomething() override external view returns (string memory) {
       return "Exterminate! Exterminate! (the bad guys)";
    }
}


contract MyLittleProxyUpgradableContract {

    // @TODO: It would be nice if there was a simple way to get
    //        this from within Solidity. Is there?
    bytes32 constant MultisigHash = 0xbcf9f099eb94a9145020c259a33f13e525711034da4034cde03868f6c19ef98a;

    ProxyMultisig _owner;
    Proxyable _target;

    event Debug(bytes32 codehash);

    constructor(ProxyMultisig owner) {

        // Make sure we are an official multisig contract with EXACTLY our
        // bells and whistles, with nothing *underhanded* going on. ;)
        require(extcodehash(address(owner)) == MultisigHash, "unsupported multisig");

        // Set the owner and target for our proxy
        _owner = owner;
        _target = _owner.getTargetAddress();

        // For debugging, to get the codehash of the multisig;
        // could be part of the build/deploy process...
        emit Debug(extcodehash(address(_owner)));
    }

    // Really want access to the codehash
    function extcodehash(address addr) public view returns (bytes32 codeHash) {
        assembly { codeHash := extcodehash(addr) }
    }

    // Execute an upgrade
    // Anyone can call this. If there was no change in the multisig, this
    // will remain unchanged
    function upgrade() public returns (address newTarget) {
        // Make sure the contract was not self-destructed;
        require(extcodehash(address(_owner)) == MultisigHash, "multisig destroyed; no longer upgradable");

        // Upgrade to the new target
        _target = Proxyable(_owner.getTargetAddress());
    }

    // Here is a proxied function that anyone can call; there would
    // be many of these (or a single fallback that dispatches, but
    // for this contest, this is simpler)
    function doPublicSomething() external view returns (string memory) {
        return _target.doPublicSomething();
    }

}
