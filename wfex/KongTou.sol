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
    
    event sendWfecEvn(address indexed _to,uint256 indexed _value);
    
    event sendWfcEvn(uint256 indexed _type,address indexed _to,uint256 indexed _usdtNum);
    
    function sendWfec(address _to,uint256 _value) public onlyOwner{
        wfec.transfer(_to,_value);
        emit sendWfecEvn(_to,_value);
    }
    

    function sendWfc(uint256 _type,address _to,uint256 _value,uint256 _usdtNum) public onlyOwner{
        wfc.transfer(_to,_value);
        emit sendWfcEvn(_type,_to,_usdtNum);
    }

    
    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }
    
        
    
}