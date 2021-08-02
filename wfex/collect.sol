// SPDX-License-Identifier: SimPL-2.0
import './interface/IERC20.sol';
import './library/SafeMath.sol';
import './interface/IERC20.sol';
pragma solidity ^0.6.10;




contract collect{
    using SafeMath for uint;
    
    uint256 public totalAmount = 1000000000000000000000000 ;//总募集金额 1000000 USDT
    
    uint256 public alreadyAmount;//已募集金额
    
    uint256 public convertRate = 10;//USDT兑换 WFC的比例  1:10
    
    uint256 public collectStartTime=1627797991;//募集开始时间
    
    uint256 public collectEndTime=1630390018;//募集结束时间
    
    uint256 public drawCoinTime = 1627797991;//提币时间
    
    address public owner;//合约管理者
    
    IERC20 public usdtToken;//usdtToken
    
    IERC20 public wfcToken;//wfc token
    
    
    struct Player{
         address walletAddress;//用户钱包地址
         uint256 totalUsdtNum;//用户总募集USDT金额
         uint256 totalWfcNum;//总提取WFC数量
    }
    
     mapping(address => Player) playerInfo;//用户募集信息
    
    constructor(address _wfcAddr,address _usdtAddr,address _owner) public{
        wfcToken=IERC20(_wfcAddr);
        usdtToken=IERC20(_usdtAddr);
        owner = _owner;
    }  
    
    
    event convertEvn(address indexed _owner, uint indexed usdtNum);
    
    function convert(uint256 usdtNum) public returns(bool){
        uint256 getNowTime = now;//获取当前时间
        require(getNowTime >= collectStartTime,"Recruitment has not started");
        require(getNowTime <= collectEndTime,"Recruitment has ended");
        uint256 totaoCollectUsdt = alreadyAmount.add(usdtNum);
        require(totaoCollectUsdt <= totalAmount,"Insufficient balance");
        address _owner = msg.sender;
        if(playerInfo[_owner].totalUsdtNum <= 0){//用户第一次质押
            Player memory player = Player(_owner,usdtNum,0);
            playerInfo[_owner] = player;
        }else{
            Player memory player = playerInfo[_owner];
            player.totalUsdtNum=player.totalUsdtNum.add(usdtNum);
            playerInfo[_owner] = player;
        }
        alreadyAmount = alreadyAmount.add(usdtNum);
        usdtToken.transferFrom(_owner,address(this),usdtNum);
        emit convertEvn(_owner,usdtNum);
        return true;
    }
    
    event sendWfcEvn( address indexed _owner, uint256 indexed _wfcNum);
    
    function sendWfc() public returns(bool){
        uint256 getNowTime = now;//获取当前时间
        require(getNowTime >= drawCoinTime,"has not started");
        address _owner = msg.sender;
        require(playerInfo[_owner].totalUsdtNum > 0,"Insufficient balance");
        Player memory player = playerInfo[_owner];
        uint256 _totalUsdtNum = player.totalUsdtNum;
        uint256 wfcNum =_totalUsdtNum.div(usdtToken.decimals()).mul(wfcToken.decimals()).mul(convertRate);//总共可以领取的wfc数量
        uint256 totalWfcNum = player.totalWfcNum;//已提取的WFC数量
        require(totalWfcNum < wfcNum,"Insufficient balance");
        uint256 nowWfcNum = wfcNum.sub(totalWfcNum);
        player.totalWfcNum = wfcNum;
        playerInfo[_owner] = player;
        wfcToken.transfer(_owner,nowWfcNum);
        emit sendWfcEvn(_owner,nowWfcNum);
        return true;        
    }


    function sendUsdt(address _owner) public onlyOwner returns(bool){
        require(_owner != address(0x0));
        usdtToken.transfer(_owner,usdtToken.balanceOf(address(this)));
    }
    
    function getPageInfo() public view returns(uint256 ,uint256 ,uint256){
        address _owner = msg.sender;
        uint256 _wfcNum = 0;
        if(playerInfo[_owner].totalUsdtNum > 0){
             Player memory player = playerInfo[_owner];
             uint256 _totalUsdtNum = player.totalUsdtNum;
            _wfcNum =_totalUsdtNum.div(usdtToken.decimals()).mul(wfcToken.decimals()).mul(convertRate);
        }
         return(alreadyAmount,drawCoinTime,_wfcNum);
    }
    
    
    
    modifier onlyOwner(){
        require(owner == msg.sender,"Must be an owner");
        _;
    }
}