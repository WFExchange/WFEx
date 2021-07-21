// SPDX-License-Identifier: SimPL-2.0
import './interface/IERC20.sol';
import './library/SafeMath.sol';
pragma solidity ^0.6.10;

contract KongTou{ 
    
    
    address public owner;
    
    
    IERC20 public wfc;
    
    IERC20 public wfec;
    
    constructor(address wfc_addr,address wfec_addr,address _owner) public{
        wfc = IERC20(wfc_addr);
        wfec =IERC20(wfec_addr);
        owner = _owner;
    }
    
    function sendWfec(address _to,uint256 _value) public onlyOwner{
        wfec.transfer(_to,_value);
    }
    

    function sendWfc(address _to,uint256 _value) public onlyOwner{
        wfc.transfer(_to,_value);
    }

    
    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }
    
        
    
}