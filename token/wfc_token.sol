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


interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) ;
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenWFC is Erc20Token {
    using SafeMath for uint256;
    uint256 public totalSupply = 1000000000 * 100000000;
    string public name = "World Finance Coin";
    string public symbol = "WFC";
    uint8 public constant decimals = 8;
    address public owner;
    mapping (address => uint256) balance;  
    mapping (address => mapping (address => uint256)) allowed; 
    
    mapping(address => address) whiteAddress;
    
    address public heidong;
    
    address public fenhong;
    
    address public zhiyaAddress;
    
    constructor(address _owner) public {
        owner = _owner;
        balance[owner] = totalSupply;
    }
  
    
    function setHeiDong(address _heidong) public onlyOwner{
        heidong = _heidong;
    }
    
    
    function setFenHong(address _fenhong) public onlyOwner{
        fenhong = _fenhong;
    }
    
    function setZhiYa(address _zhiya) public onlyOwner{
        zhiyaAddress = _zhiya;
    }    
    
    function addWhite(address _white) public onlyOwner{
        whiteAddress[_white]=_white;
    }
    
    function delWhite(address _white) public onlyOwner{
        delete whiteAddress[_white];
    }
  
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0));
        uint256 reladAmount;
        if(whiteAddress[_to] == address(0x0)){
            uint256 burnValue = _value.mul(5)/100;
            uint256 heidongValue = burnValue.mul(20)/100;
            uint256 zhiyaValue = burnValue.mul(20)/100;
            uint256 fenhongValue = burnValue.mul(60)/100;
            balance[zhiyaAddress]=balance[zhiyaAddress].add(zhiyaValue);
            balance[fenhong]=balance[fenhong].add(fenhongValue);
            balance[heidong]=balance[heidong].add(heidongValue);      
            reladAmount = _value.sub(burnValue);
        }else{
            reladAmount = _value;
        }
        require(balance[msg.sender] >= _value && balance[_to] + reladAmount > balance[_to]);
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(reladAmount);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }



    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0x0) && _from != address(0x0) ,'_from is invalid or _to is invalid');
        uint256 reladAmount;
        if(whiteAddress[_to] == address(0x0)){
            uint256 burnValue = _value.mul(10)/100;
            uint256 heidongValue = burnValue.mul(30)/100;
            uint256 zhiyaValue = burnValue.mul(30)/100;
            uint256 fenhongValue = burnValue.mul(40)/100;
            balance[zhiyaAddress]=balance[zhiyaAddress].add(zhiyaValue);
            balance[fenhong]=balance[fenhong].add(fenhongValue);
            balance[heidong]=balance[heidong].add(heidongValue);      
            reladAmount = _value.sub(burnValue);
        }else{
            reladAmount = _value;
        }        
        require(balance[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balance[_from] = balance[_from].sub(_value);
        balance[_to] = balance[_to].add(reladAmount);
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

    modifier onlyOwner(){
        require(msg.sender ==  owner,'Must be the owner');
        _;
    }

}