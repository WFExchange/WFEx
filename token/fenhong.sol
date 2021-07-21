// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract FenHong{  
    
    IERC20 wfcAddr;
    
    constructor(address _wfcAddr) public{
        wfcAddr = IERC20(_wfcAddr);
    }
    
    function transferFrom(address _toAddress,uint256 _value) public returns(bool){
            return wfcAddr.transferFrom(address(this),_toAddress,_value);
    }
    
    function balance() public view returns (uint256){
        return wfcAddr.balanceOf(address(this));
    }
    
}