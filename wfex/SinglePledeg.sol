// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;

pragma experimental ABIEncoderV2;
import './interface/IERC20.sol';
import './library/Address.sol';
import './library/SafeMath.sol';
import './library/strings.sol';
import './BrunFaFang.sol';
contract SinglePledeg{
    using strings for *;
    using SafeMath for uint;
    address public owner;
    
    IERC20 private wfc;

    BrunFaFang private brunFaFang;
    
    mapping(address=> PledgePool) public tokenPledge;
    
    mapping(string=> PledgePool) public codePledge;
    
    mapping(address => uint256) public userPledgeRecord;
    
    address[] userAddressArray;
    
    PledgePool[] public pledgePoolArray;

    constructor(address _owner,address _wfcAddress,address burnAddress) public {
        owner = _owner;
        wfc= IERC20(_wfcAddress);
        brunFaFang=BrunFaFang(burnAddress);
    }
    
    struct PledgePool{
        string poolCode;
        uint256 totalNum;
        uint256 lastNum;
        address tokenERC;
        uint   decimal;
        address createAuth;
    }
     
     
    struct PledgeRecord{
         address userWalletAddress;
         string  parentPoolCode;
         uint    poolId;
         uint256 totalNum;
         uint256 lastNum;
         uint256 totalIncome;
         uint256 lastIncome;
         uint    atLastTime;
    }
    
    mapping(address => mapping(string=>PledgeRecord)) userRecord;
    
    event pledgeEvn(address indexed _owner,uint indexed poolId,uint256 indexed _value);
    
    event canclePledgeEvn(address indexed _owner,uint256 indexed _value,uint indexed poolId);
    
    event sendWfcEvn(address indexed _owner,uint256 indexed _value,uint indexed poolId);
    
    event addPoolEvn(uint indexed poolId,uint256 indexed totalNum,address indexed contractAddress);
    
    function addPool(string memory poolCode,uint256 totalNum,address contractAddress) public  onlyOwner returns(bool){
        IERC20 token =  IERC20(contractAddress);
         PledgePool memory pledgePool = PledgePool(poolCode,totalNum,0,contractAddress,token.decimals(),msg.sender);
         tokenPledge[contractAddress] = pledgePool;
         pledgePoolArray.push(pledgePool);
         codePledge[poolCode]= pledgePool;
    }
    

    function pledge(uint256 _value,uint _poolId,string memory _poolCode) external returns(bool){
        address _owner = msg.sender;
        require(codePledge[_poolCode].totalNum > 0,"please create before");
        address contractAddress = codePledge[_poolCode].tokenERC;
        IERC20 erc20 = IERC20(contractAddress);
        PledgeRecord memory pledgeRecord = userRecord[_owner][_poolCode];
        if(pledgeRecord.totalNum > 0){//当前池子用户已经质押过
            pledgeRecord.totalNum = pledgeRecord.totalNum.add(_value);
            pledgeRecord.lastNum = pledgeRecord.lastNum.add(_value);
            userRecord[_owner][_poolCode] = pledgeRecord;
            userAddressArray.push(_owner);
        }else{
            pledgeRecord = PledgeRecord(_owner,_poolCode,_poolId,_value,_value,0,0,block.timestamp);
            userRecord[_owner][_poolCode] = pledgeRecord;
        }
        erc20.transferFrom(_owner,address(this),_value);
        emit pledgeEvn(_owner,_poolId,_value);
        return true;
    }

    function canclePledge(uint256 _value,string memory _poolCode) external returns(bool){
        address _owner = msg.sender;
        PledgeRecord memory pledgeRecord = userRecord[_owner][_poolCode];
        require(pledgeRecord.totalNum > 0 ,'no pledge');
        require(pledgeRecord.lastNum >= _value,'Insufficient balance');
        uint poolId = pledgeRecord.poolId;
        address contractAddress =codePledge[pledgeRecord.parentPoolCode].tokenERC;  
        IERC20 erc20 = IERC20(contractAddress);
        pledgeRecord.lastNum = pledgeRecord.lastNum.sub(_value);
        userRecord[_owner][_poolCode] = pledgeRecord;
        erc20.transfer(_owner,_value);
        emit canclePledgeEvn(_owner,_value,poolId);
    }
    
    

    function sendWfcAdmin(address _owner,string memory _poolCode,uint256 wfcNum) external onlyOwner returns(bool){
        require(!brunFaFang.isExits(_owner),'IS blacklist');
        PledgeRecord memory pledgeRecord = userRecord[_owner][_poolCode];
        require(pledgeRecord.totalNum > 0 ,'Insufficient balance');
        pledgeRecord.lastIncome = 0;
        uint poolId = pledgeRecord.poolId;
        userRecord[_owner][_poolCode] = pledgeRecord;
        wfc.transfer(_owner,wfcNum);
        emit sendWfcEvn(_owner,wfcNum,poolId);
        return true;
    } 
    

    function canclePledgeAndSendWfcAdmin(string memory _poolCode,address _owner,uint256 wfcNum,uint256 _value) external returns(bool){
        require(!brunFaFang.isExits(_owner),'IS blacklist');
        PledgeRecord memory pledgeRecord = userRecord[_owner][_poolCode];
        require(pledgeRecord.totalNum > 0 ,'Insufficient balance');
        address contractAddress =codePledge[pledgeRecord.parentPoolCode].tokenERC;  
        IERC20 erc20 = IERC20(contractAddress);
        pledgeRecord.lastNum = pledgeRecord.lastNum.sub(_value);
        uint poolId = pledgeRecord.poolId;
         pledgeRecord.lastIncome = 0;
        userRecord[_owner][_poolCode] = pledgeRecord;
        erc20.transfer(_owner,_value);
        wfc.transfer(_owner,wfcNum);
        emit canclePledgeEvn(_owner,_value,poolId);
        emit sendWfcEvn(_owner,wfcNum,poolId);
    }



    // function setIncomeAdmin(address _owner,string memory _poolCode,uint256 _totalIncome,uint256 _lastIncome) external onlyOwner returns(bool){
    //     PledgeRecord memory pledgeRecord = userRecord[_owner][_poolCode];
    //     require(pledgeRecord.totalNum > 0 ,'Insufficient balance');
    //     pledgeRecord.lastIncome = _lastIncome;
    //     pledgeRecord.totalIncome = _totalIncome;
    //     userRecord[_owner][_poolCode] = pledgeRecord;
    //     return true;
    // }
    
    
    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }
    

    function append(string memory s1, string memory s2) private pure returns(string memory){
        return s1.toSlice().concat(s2.toSlice());
    }
    
    
    function toBytesNickJohnson(uint256 x) private pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function getStr(uint playChoice) private pure returns (string memory s) {
        bytes memory c = toBytesNickJohnson(playChoice);
        return string(c);
    }    
    

}