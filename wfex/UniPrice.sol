// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;


interface UniPrice{
    function getPrice(address token1,address token2) external view returns(uint256 amount1,uint256 amount2);    
}