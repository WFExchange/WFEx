// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;

import './interface/IERC20.sol';
import './library/SafeMath.sol';

contract BrunFaFang{
    
    IERC20 private wfc;
    
    address private owner;
    
    mapping(address => address) blackAddrMap;
    
    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }    
    constructor(address wfc_addr,address _owner) public{
        wfc=IERC20(wfc_addr);
        owner = _owner;
    }
    
    function sendWfc(address[] memory _to,uint256[] memory _value) public onlyOwner returns(bool){
         for(uint8 i=0;i<_to.length;i++){
            if(_to[i] != address(0)){
                wfc.transfer(_to[i],_value[i]);
            }
         }
         return true;
    }
    
    function isExits(address _addr) public view returns(bool){
        if(blackAddrMap[_addr] == address(0)){
            return false;
        }else{
            return true;
        }
    }
    
    function addBlack(address _addr) external onlyOwner returns(bool){
        require(_addr != address(0),'param is error');
        require(blackAddrMap[_addr] == address(0),'exist blacklist');
        blackAddrMap[_addr] = _addr;
        return true;
    }
    
    
    function delBlack(address _addr) external onlyOwner returns(bool){
        require(_addr != address(0),'param is error');
        require(blackAddrMap[_addr] != address(0),'exist blacklist');
        delete blackAddrMap[_addr];
        return true;
    }
    
    function getBalance() public view returns(uint256){
        wfc.balanceOf(address(this));
    }
    
}