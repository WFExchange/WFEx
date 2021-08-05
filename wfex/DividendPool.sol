// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;

pragma experimental ABIEncoderV2;
import './interface/IERC20.sol';
import './library/Address.sol';
import './library/SafeMath.sol';
import './BrunFaFang.sol';
import './UniPrice.sol';

contract DividendPool{ 
    
    using Address for address;
    using SafeMath for uint;
    
    BrunFaFang private brunFaFang;
    
    UniPrice public uinPrice;
    
    address public usdtAddress;
    
    
    IERC20 public wfc;
    
    address public WFC_ADDR;
    
    IERC20 public wfec;
    
    address public WFEC_ADDR;
    
    address public owner;
    
    uint256 public WEI_WFC;
    
    uint256 private WEI_WFEC;
    
    uint256 public MIAO_INCOME_FENZI = 1388;
    
    uint256 public YEAR_RATE = 73000000000;
    
    uint256 private totalWfecValue;
    
    uint256 private myUnit = 10 ** 6;
    
    uint256 private rateUnit = 10 ** 8;
    
    
    
    
    struct Player{
         address walletAddress;
         uint  join_timestamp;
         uint  pledgeTime;
         uint  next_profit_time;
         uint256 totalValue;
         uint256 lastValue;
         uint256 totalIncome;
         uint256 lastIncome;
         uint256 destroyWfec;
    }
    
    mapping(address => Player) playerInfo;    
    
    constructor(address _wfcAddr,address _wfecAddr,address _owner,address burnAddress,address _uniAddress,address _usdtAddress) public{
        WFC_ADDR =_wfcAddr;
        wfc = IERC20(WFC_ADDR);
        WFEC_ADDR = _wfecAddr;
        wfec=IERC20(WFEC_ADDR);
        owner = _owner;
        WEI_WFC =10 ** 8;
        WEI_WFEC =10 ** 8;
        brunFaFang=BrunFaFang(burnAddress);
        uinPrice = UniPrice(_uniAddress);
        usdtAddress = _usdtAddress;
    }      
    

    event pledgeTokenEvn(address indexed fromAddress, uint indexed value);
    
    

    function findPlayerInfo() public view returns(uint256 _totalWfecValue,uint256 _YEAR_RATE,uint256 _usdtWfcPrice,uint256 _wfcNum,
    uint256 _incomeNum,uint256 _wfecNum,uint256 _hisWfecNum,uint256 _hisWfcNum,uint256 _hisDestWfecNum,uint256 pledgeTime                    
    ){
        address _owner = msg.sender;
        //require(_owner != address(0),'request error');
        _totalWfecValue = totalWfecValue;
        _YEAR_RATE = YEAR_RATE;
        _usdtWfcPrice = getWfcUsdtPrice();
         _wfcNum = wfc.balanceOf(address(this));
        if(playerInfo[_owner].totalValue <= 0){
            return(_totalWfecValue,_YEAR_RATE,_usdtWfcPrice,_wfcNum,0,0,0,0,0,0);
        }
        Player memory player = playerInfo[_owner];
         _wfecNum = player.lastValue;
        _incomeNum =player.lastIncome.add(getTotalIncome(player.next_profit_time,_wfecNum,player.lastIncome));
        _hisWfecNum = player.totalValue;
        _hisWfcNum = player.totalIncome;
        _hisDestWfecNum = player.destroyWfec;
        return(_totalWfecValue,_YEAR_RATE,_usdtWfcPrice,_wfcNum,_incomeNum,_wfecNum,_hisWfecNum,_hisWfcNum,_hisDestWfecNum,player.pledgeTime);
    }


    function pledgeToken(uint256 _value) public onlyAuthModify returns(bool){
        address _owner = msg.sender;
        if(playerInfo[_owner].totalValue <= 0){
            Player memory player = Player(msg.sender,block.timestamp,block.timestamp,block.timestamp,_value,_value,0,0,0);
            playerInfo[_owner] = player;
        }else{
            Player memory player = playerInfo[msg.sender];
            player.totalValue=player.totalValue.add(_value);
            uint256 incomeVaue = getTotalIncome(player.next_profit_time,player.lastValue,player.lastIncome);
            uint256 lastValue = player.lastValue.add(_value);
            player.lastValue=lastValue;
            player.lastIncome = player.lastIncome.add(incomeVaue);
            player.next_profit_time = block.timestamp;
            playerInfo[msg.sender] = player;
        }
        totalWfecValue =totalWfecValue.add(_value); 
        wfec.transferFrom(_owner,address(this),_value);
        emit pledgeTokenEvn(_owner,_value);
    }
    
    
    
    event sendWfecEvn(address indexed _owner,uint256 indexed wfecNum); 
    
    function sendWfec(uint256 _value) public onlyAuthModify returns(bool){
        address _owner = msg.sender;
        require(playerInfo[_owner].totalValue > 0,'Insufficient balance');
        Player memory player = playerInfo[_owner];
        uint256 lastValue =  player.lastValue;
        require(lastValue >= _value,'Insufficient balance');
        uint256 incomeVaue = player.lastIncome.add(getTotalIncome(player.next_profit_time,lastValue,player.lastIncome));
        uint256 higValue = lastValue.sub(incomeVaue);
        require(higValue >= _value,'Insufficient balance');
        player.lastValue = lastValue.sub(_value);
        player.lastIncome = incomeVaue;
        player.next_profit_time = block.timestamp;        
        playerInfo[_owner] = player;
        totalWfecValue = totalWfecValue.sub(_value);
        wfec.transfer(_owner,_value);
        emit sendWfecEvn(_owner,_value);
        return true;
    }    
    
     event sendWfcEvn(address indexed _owner,uint256 indexed wfecNum);     

    function sendWfc(uint256 _wfcNum) public onlyAuthModify returns(bool){
        address _owner = msg.sender;
        require(!brunFaFang.isExits(_owner),'IS blacklist');
        require(playerInfo[_owner].totalValue > 0,'Insufficient balance');
        Player memory player = playerInfo[_owner];
        uint256 _incomeNum =player.lastIncome.add(getTotalIncome(player.next_profit_time,player.lastValue,player.lastIncome));
        require(_wfcNum <= _incomeNum,'Insufficient balance income');
        _incomeNum = _wfcNum;
        uint256 lastValue =  player.lastValue;
        uint256 usdtNum = _incomeNum;
        uint256 wfcNum = usdtNum.mul(myUnit).div(getWfcUsdtPrice());
        uint256 destroyWfec =player.destroyWfec.add(usdtNum);
        lastValue = lastValue.sub(usdtNum);
        player.lastValue = lastValue;
        player.totalIncome = player.totalIncome.add(usdtNum);
        player.lastIncome = 0;
        player.destroyWfec = destroyWfec;
        player.next_profit_time = block.timestamp;
        playerInfo[_owner] = player;
        wfc.transfer(_owner,wfcNum);
        emit sendWfcEvn(_owner,wfcNum);
        return true;
    }    
    
    function sendWfcAndWfec(uint256 wfecNum,uint256 _wfcNum) public returns(bool){
        sendWfc(_wfcNum);
        sendWfec(wfecNum);
        return true;
    }       

    function getWfcUsdtPrice() public view returns(uint256){
        (uint256 amount1,uint256 amount2) = uinPrice.getPrice(WFC_ADDR,usdtAddress);
        uint256 wfcUint = 10 ** 8;
        uint256 usdtUint = 10 ** 18;
        uint256 wfcNum = amount1.div(wfcUint,'wfcNum div error');
        uint256 usdtNum = amount2.div(usdtUint,'usdtNum div error');
        return usdtNum.mul(myUnit).div(wfcNum);
    } 
    
    
    
    function getTotalIncome(uint _nextTime,uint _wfecNum,uint256 _lstIncome) private view returns(uint256){
        uint256 nowTime = now;
        if(nowTime <= _nextTime){
            return 0;
        }else{
            uint256 difseconds = nowTime.sub(_nextTime);
            uint256 secondsm = 60;
            uint minutesm = difseconds.div(secondsm);
            uint256 wfecNum = _wfecNum.div(rateUnit);
            uint256 lastIncome = MIAO_INCOME_FENZI.mul(minutesm).mul(wfecNum);
            uint256 totalIncome = lastIncome.add(_lstIncome);
            if(totalIncome > _wfecNum){
                lastIncome = _wfecNum.sub(_lstIncome);
            }
            return lastIncome;
        }
    }

    function setRate(uint _YEAR_RATE,uint _MIAO_INCOME_FENZI) public onlyOwner returns(bool){
        YEAR_RATE = _YEAR_RATE;
        MIAO_INCOME_FENZI = _MIAO_INCOME_FENZI;
        return true;
    }


    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }
   modifier onlyAuthModify(){
        require(!isContract(msg.sender),"contract not allowed");
        require(msg.sender==tx.origin,"proxy contract not allowed");
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size>0;
    }    
    
}