// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;

pragma experimental ABIEncoderV2;
import './interface/IERC20.sol';
import './library/Address.sol';
import './library/SafeMath.sol';
import './BrunFaFang.sol';


contract PoolPledge{
    using SafeMath for uint;
        
    address public owner;

    IERC20 public wfc;

    BrunFaFang private brunFaFang;
    
    mapping(uint=> PledgePool) public poolIdToPledge;
    
    struct PledgePool{
        uint poolId;
        IERC20 erc20;
        uint256 totalNum;
        uint decimal;
    }    
    
    struct PledgeRecord{
         uint    poolId;
         uint totalNum;
    }
    
    mapping(address => mapping(uint=>PledgeRecord)) userRecord;
    
    constructor(address _owner,address _wfcAddress,address burnAddress) public {
        owner = _owner;
        wfc= IERC20(_wfcAddress);
        brunFaFang=BrunFaFang(burnAddress);
    }    
    
    function addPool(uint64  poolId,address contractAddress) public  onlyOwner returns(bool){
         require(poolIdToPledge[poolId].totalNum <= 0,'poolId is alerted');
         IERC20 token =  IERC20(contractAddress);
         uint decimal =token.decimals();
         PledgePool memory pledgePool = PledgePool(poolId,token,200,decimal);
         poolIdToPledge[poolId] = pledgePool;
         return true;
    }    
    
    event pledgeEvn(address indexed _owner,uint indexed poolId,uint256 indexed _value);
    
    function pledge(uint256 _value,uint _poolId) external returns(bool){
        address _owner = msg.sender;
        require(poolIdToPledge[_poolId].totalNum > 0,"please create before");
        IERC20 token = poolIdToPledge[_poolId].erc20;
        PledgeRecord memory pledgeRecord = userRecord[_owner][_poolId];
        if(pledgeRecord.totalNum > 0){
            pledgeRecord.totalNum = pledgeRecord.totalNum.add(_value);
            userRecord[_owner][_poolId] = pledgeRecord;
        }else{
            PledgeRecord memory myPledgeRecord = PledgeRecord(_poolId,_value);
            userRecord[_owner][_poolId] = myPledgeRecord;
        }
        token.transferFrom(_owner,address(this),_value);
        emit pledgeEvn(_owner,_poolId,_value);
        return true;
    }    
    
    event canclePledgeEvn(address indexed _owner,uint256 indexed _value,uint indexed poolId);
    
    function canclePledge(uint256 _value,uint _poolId) external returns(bool){
        address _owner = msg.sender;
        PledgeRecord memory pledgeRecord = userRecord[_owner][_poolId];
        require(pledgeRecord.totalNum > 0 ,'no pledge');
        require(pledgeRecord.totalNum >= _value,'Insufficient balance');
        IERC20 token  = poolIdToPledge[_poolId].erc20;
        pledgeRecord.totalNum = pledgeRecord.totalNum.sub(_value);
        userRecord[_owner][_poolId] = pledgeRecord;
        token.transfer(_owner,_value);
        emit canclePledgeEvn(_owner,_value,_poolId);
    }    
    
     
    
    event sendWfcEvn(address indexed _owner,uint256 indexed _value,uint indexed poolId);
    
    function sendWfcAdmin(address _owner,uint _poolId,uint256 wfcNum) external onlyOwner returns(bool){
        require(!brunFaFang.isExits(_owner),'IS blacklist');
        wfc.transfer(_owner,wfcNum);
        emit sendWfcEvn(_owner,wfcNum,_poolId);
        return true;
    }

    function canclePledgeAndSendWfcAdmin(uint _poolId,address _owner,uint256 wfcNum,uint256 _value) external returns(bool){
        require(!brunFaFang.isExits(_owner),'IS blacklist');
        if(_value > 0){
            require(userRecord[_owner][_poolId].totalNum > 0 ,'Insufficient balance');
        
            PledgeRecord memory pledgeRecord = userRecord[_owner][_poolId];
            IERC20 token  = poolIdToPledge[_poolId].erc20; 
            pledgeRecord.totalNum = pledgeRecord.totalNum.sub(_value);
            userRecord[_owner][_poolId] = pledgeRecord;
            token.transfer(_owner,_value);
             emit canclePledgeEvn(_owner,_value,_poolId);
        }
        wfc.transfer(_owner,wfcNum);
        emit sendWfcEvn(_owner,wfcNum,_poolId);
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }

}