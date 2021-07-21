// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;
abstract contract Erc20Token{  
    
    function balanceOf(address _owner) public view virtual returns (uint256 val);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract TokenWFEC is Erc20Token {
    using SafeMath for uint256;
    uint256 public totalSupply;
    string public name = "World Finance Coin";
    string public symbol = "WFEC";
    uint8 public decimals = 8;
    address public owner;
    mapping (address => uint256) balance;  
    mapping (address => mapping (address => uint256)) allowed;  
    
    constructor(address _owner,uint256 _totalSupply) public {
        totalSupply = _totalSupply * 100000000;
        owner = _owner;
        balance[owner] = totalSupply;
    }
  
    event AddSupply(uint256 amount);
    
    event changeOwnerEvt(address _newOwner);
  
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0));
        require(balance[msg.sender] >= _value && balance[_to] + _value > balance[_to]);
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0));
        require(balance[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balance[_from] = balance[_from].sub(_value);
        balance[_to] = balance[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 val) {  
        return balance[_owner];
    }
  
    function approve(address _spender, uint256 _value) public override returns (bool success) {   
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {  
        return allowed[_owner][_spender];
    }

    function changeOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
        emit changeOwnerEvt(_newOwner);
    } 

    function addTotalSupply(uint256 _amount) public onlyOwner{
        totalSupply = totalSupply.add(_amount * 100000000);
        balance[owner] = balance[owner].add(_amount);
        emit AddSupply(_amount);
    }

    modifier onlyOwner(){
        require(msg.sender ==  owner,'Must be the owner');
        _;
    }

}