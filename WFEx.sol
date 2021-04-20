pragma solidity =0.5.16;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

contract HC_game {
    using UniswapV2Library for uint256;
    using SafeMath128 for uint128;
    using SafeMath for uint;

    IERC20 private token0;
    IERC20 private token6;
    IUniswapV2Pair private token1;
    IUniswapV2Pair private token2;
    IUniswapV2Pair private token3;

    uint32 constant private TIME_BASE = 1606752000;

    uint64 private WEI_WFC;
    uint64 private WEI_USDT;
    uint64 private WEI_WFC_USDT;
    uint64 private WEI_WFC_BTC;
    uint64 private WEI_WFC_HT;

    address private owner = 0x7f1786d0730dDaD6202C16678CE802ABB60F4df5;
    address constant private ADMIN_ADDR = 0x629c38881c9462f181d10A0B2C8192f240A86815;
    address private op_addr = 0xb28C7D5BD97aDa20426573baa49A78c062De5920;

    address public WFC_ADDR = 0x781bC268da2e1dD0c8Cb2A2A8B3360BBA530b24e;
    address public USDT_addr=0xa71EdC38d189767582C38A3145b5873052c3e47a;
    address public WFC_USDT_PAIR_ADDR = 0xD2d8Ff7E251505fA9e274fDbf7Db55F050D9DDea;
    address public WFC_BTC_PAIR_ADDR=0x71bb5029d33b36dfa859D82498dd58787D6a530a;
    address public WFC_HT_PAIR_ADDR=0x43c7C1f0932aA73E6Cf95Eb98A9e3b26c4d9FA83;

    event ev_join(address indexed addr, uint64 playid, uint256 _value, uint8 token_type,uint64 ref_id);
    event ev_withdraw_wfc(address indexed addr, uint256 _value);
    event ev_withdraw_pair(address indexed addr, uint256 _value, uint8 _pair_type);
    event ev_withdraw_admin(address indexed addr,   uint8 token_type,  uint256 _value, string comment);
    event ev_pay_bond(uint64 uid,uint128 _value,uint8 _type,uint128 _pirce,uint128 _get);

    struct Player {
        uint128 total_wfc;
        uint128 total_wfb;
        uint128 total_wfc_usdt_lp;
        uint128 total_wfc_btc_lp;
        uint128 total_wfc_ht_lp;
        uint128 withdraw_wfc;
        uint128 withdraw_wfc_usdt_lp;
        uint128 withdraw_wfc_btc_lp;
        uint128 withdraw_wfc_ht_lp;
        uint128 sendUSDT;
        uint128 nowWFC;
        uint32  join_timestamp;
        uint64  ref_id;
    }

     Player[] public players;
     mapping (address => uint64) public playerIdx;
     mapping (uint64 => address) public idToAddr;

    uint128  private limit=0;
    uint128  public total_pay=0;
    uint64   private percent=0;
    uint64   private WEI_percent=10**8;
    uint64   private startTime=0;
    uint64   private endTime=0;
    uint8    private raise_open=0;

    uint128  public bondWfcMin;
    uint128  public bondWfbMax;

    modifier onlyAdmin() {
        require(msg.sender == ADMIN_ADDR);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == op_addr);
        _;
    }

    constructor() public {

        token0 = IERC20(WFC_ADDR);
        WEI_WFC =10 ** uint64(token0.decimals());

        token6 = IERC20(USDT_addr);
        WEI_USDT =10 ** uint64(token6.decimals());

        if(WFC_USDT_PAIR_ADDR != address(0)){
            token1 = IUniswapV2Pair(WFC_USDT_PAIR_ADDR);
            WEI_WFC_USDT =10 ** uint64(token1.decimals());
        }
        if(WFC_BTC_PAIR_ADDR != address(0)){
            token2 = IUniswapV2Pair(WFC_BTC_PAIR_ADDR);
            WEI_WFC_BTC =10 ** uint64(token2.decimals());
        }
        if(WFC_HT_PAIR_ADDR != address(0)){
            token3 = IUniswapV2Pair(WFC_HT_PAIR_ADDR);
            WEI_WFC_HT =10 ** uint64(token3.decimals());
        }
        Player memory _player = Player({
        total_wfc : 0,
        total_wfb :0,
        total_wfc_usdt_lp : 0,
        total_wfc_btc_lp : 0,
        total_wfc_ht_lp : 0,
        withdraw_wfc : 0,
        withdraw_wfc_usdt_lp : 0,
        withdraw_wfc_btc_lp : 0,
        withdraw_wfc_ht_lp : 0,
        ref_id :0,
        join_timestamp: uint32(block.timestamp-TIME_BASE),
        sendUSDT : 0,
        nowWFC : 0
        });

        players.push(_player);
        players.push(_player);
        uint64 playerId = uint64(players.length - 1);
        playerIdx[owner] = playerId;
        idToAddr[playerId] = owner;
    }
    
    function register(address user_address,address _ref_address) public{
        require(user_address!=address(0),"user address error");
        require(playerIdx[user_address] == 0,"user is exit");
        
        uint64 _ref_id=playerIdx[_ref_address];
        if(idToAddr[_ref_id]==address(0)){
            _ref_id=playerIdx[owner];
        }
        
        Player memory _player = Player({
        total_wfc : 0,
        total_wfb :0,
        total_wfc_usdt_lp : 0,
        total_wfc_btc_lp : 0,
        total_wfc_ht_lp : 0,
        withdraw_wfc : 0,
        withdraw_wfc_usdt_lp : 0,
        withdraw_wfc_btc_lp : 0,
        withdraw_wfc_ht_lp : 0,
        join_timestamp: uint32(block.timestamp-TIME_BASE),
        sendUSDT : 0,
        nowWFC : 0,
        ref_id:_ref_id
        });
        players.push(_player);
        uint64 playerId = uint64(players.length - 1);
        playerIdx[user_address] = playerId;
        idToAddr[playerId] = user_address;
        emit ev_join(user_address, playerId,0, 0,_ref_id);
    }

    function bond_setting (uint128 _bondWfcMin,uint128 _bondWfbMax) public onlyOperator {
        require(_bondWfcMin<=_bondWfbMax,'price set error');
        bondWfcMin=_bondWfcMin;
        bondWfbMax=_bondWfbMax;
    }

    function pay_for_bond (uint128 _value,uint8 _type) public {
        uint64 playerId=playerIdx[msg.sender];
        require(idToAddr[playerId]!=address(0),'There is no user');
        Player storage this_player=players[playerId];
        uint256 wft_to_usdt_price=getPrice(1,WFC_ADDR);

        uint128 pirce=uint128(wft_to_usdt_price);
        require(pirce==wft_to_usdt_price,"price over uint128");

        uint128 pay_num;
        if(_type==1){
            require(pirce<=bondWfcMin,'price more than bondWfcMin');
            token0.transferFrom(msg.sender,address(this),_value);
            pay_num=_value.mul(WEI_WFC).div(pirce);
            players[playerId].total_wfb=this_player.total_wfb.add(pay_num);
        }else if(_type==2){
            require(pirce>=bondWfbMax,'price less than bondWfbMax');
            require(this_player.total_wfb>=_value,'total_wfb not enough');
            players[playerId].total_wfb=this_player.total_wfb.sub(_value);
            pay_num=_value.mul(pirce).div(WEI_WFC);
            token0.transfer(msg.sender, pay_num);
        }
        emit ev_pay_bond(playerId,_value,_type,pirce,pay_num);
    }

    function join(uint128 _value, uint8 _token_type,address _ref_address) public
    returns(
        uint64 playerId
    ){
        require(_token_type < 4, "Token type error");
        require(_value > 1, "Value error");

        IUniswapV2Pair pair;

        uint64 _ref_id=playerIdx[_ref_address];
        if(idToAddr[_ref_id]==address(0)){
            _ref_id=playerIdx[owner];
        }

        if(playerIdx[msg.sender] == 0){

            Player memory _player = Player({
                total_wfc : 0,
                total_wfb :0,
                total_wfc_usdt_lp : 0,
                total_wfc_btc_lp : 0,
                total_wfc_ht_lp : 0,
                withdraw_wfc : 0,
                withdraw_wfc_usdt_lp : 0,
                withdraw_wfc_btc_lp : 0,
                withdraw_wfc_ht_lp : 0,
                join_timestamp: uint32(block.timestamp-TIME_BASE),
                sendUSDT : 0,
                nowWFC : 0,
                ref_id:_ref_id
            });

            players.push(_player);
            playerId = uint64(players.length - 1);
            playerIdx[msg.sender] = playerId;
            idToAddr[playerId] = msg.sender;
        }else{
            playerId = playerIdx[msg.sender];
        }

        Player storage this_player=players[playerId];

        if(_token_type == 0){
            token0.transferFrom(msg.sender,address(this),_value);
            players[playerId].total_wfc = this_player.total_wfc.add(_value);
        }else{

            if(_token_type == 1){
                pair = token1;
                players[playerId].total_wfc_usdt_lp =this_player.total_wfc_usdt_lp.add(_value);
            }else if(_token_type == 2){
                pair = token2;
                players[playerId].total_wfc_btc_lp = this_player.total_wfc_btc_lp.add(_value);
            }else if(_token_type == 3){
                pair = token3;
                players[playerId].total_wfc_ht_lp = this_player.total_wfc_ht_lp.add(_value);
            }
            pair.transferFrom(msg.sender,address(this),_value);
        }

        emit ev_join(msg.sender, playerId, _value, _token_type,_ref_id);

    }

    function payRaiseMoney(uint128 _value,address _ref_address) public
    {
        require(raise_open==1,"raise close");
        require(_value <= uint128(limit.sub(total_pay)),'over limit');

        uint64 playerId;

        uint64 _ref_id=playerIdx[_ref_address];
        if(idToAddr[_ref_id]==address(0)){
            _ref_id=playerIdx[owner];
        }
        if(playerIdx[msg.sender] == 0){
            Player memory _player = Player({
            total_wfc : 0,
            total_wfb :0,
            total_wfc_usdt_lp : 0,
            total_wfc_btc_lp : 0,
            total_wfc_ht_lp : 0,
            withdraw_wfc : 0,
            withdraw_wfc_usdt_lp : 0,
            withdraw_wfc_btc_lp : 0,
            withdraw_wfc_ht_lp : 0,
            join_timestamp: uint32(block.timestamp-TIME_BASE),
            sendUSDT : 0,
            nowWFC : 0,
            ref_id:_ref_id
            });
            players.push(_player);
            playerId = uint64(players.length - 1);
            playerIdx[msg.sender] = playerId;
            idToAddr[playerId] = msg.sender;
        }else{
            playerId = playerIdx[msg.sender];
        }
        Player storage this_player=players[playerId];
        uint128 WFC = _value.mul(WEI_WFC).mul(percent).div(WEI_percent).div(WEI_USDT);
        players[playerId].sendUSDT = this_player.sendUSDT.add(_value);
        players[playerId].nowWFC =this_player.nowWFC.add(WFC);
        total_pay=total_pay.add(_value);

        token6.transferFrom(msg.sender,address(this),_value);
        emit ev_join(msg.sender, playerId,0, 0,_ref_id);
    }

    function getRaiseWFC(address to) public{
        require(raise_open == 0,'raise is opening');
        uint64 playerId = playerIdx[msg.sender];
        require(players[playerId].nowWFC>0,'NO WFC');
        uint128 residue_wft=players[playerId].nowWFC;
        players[playerId].nowWFC=0;
        token0.transfer(to, residue_wft);

    }

    function raise_setting(uint64 _percent,uint128 _limit,uint8 is_open,uint64 start,uint64 end) public onlyOperator{
        percent=_percent;
        limit=_limit;
        raise_open=is_open;
        startTime=start;
        endTime=end;
    }

    function get_raise_setting() public view returns(uint128 raise_usdt_pay,uint64 _percent,uint128 _limit,uint8 is_open,uint64 start,uint64 end) {
        _percent=percent;
        _limit=limit;
        is_open=raise_open;
        start=startTime;
        end=endTime;
        raise_usdt_pay=total_pay;
    }

    function withdrawWfc(address to, uint _amt) public onlyOperator {
        require(_amt <= token0.balanceOf(address(this)), "Not enough balance.");
        token0.transfer(to, _amt);
        emit ev_withdraw_wfc(to, _amt);
    }

    function withdrawPair(address to, uint128 _amt, uint8 _pair_type) public onlyOperator {
        uint64 playId = playerIdx[to];
        require(playId > 0, "You have not registered");
        require(_pair_type > 0 && _pair_type < 4, "Pair type error");
        Player storage _p = players[playId];
        IUniswapV2Pair pair;
        if(_pair_type == 1){
            pair = token1;
            _p.withdraw_wfc_usdt_lp = _p.withdraw_wfc_usdt_lp.add(_amt);
        }else if(_pair_type == 2){
            pair = token2;
            _p.withdraw_wfc_btc_lp = _p.withdraw_wfc_btc_lp.add(_amt);
        }else if(_pair_type == 3){
            pair = token3;
            _p.withdraw_wfc_ht_lp = _p.withdraw_wfc_ht_lp.add(_amt);
        }

        require(_amt <= pair.balanceOf(address(this)), "Not enough balance.");
        pair.transfer(to, _amt);

        emit ev_withdraw_pair(to, _amt, _pair_type);
    }

    function withdrawAdmin(uint256 val, uint8 _token_type) public onlyAdmin {
        require(_token_type <5, "Token type error");
        if(_token_type == 0){
            require(val <= token0.balanceOf(address(this)), "Not enough balance.");
            token0.transfer(address(uint160(ADMIN_ADDR)),val);
        }else if(_token_type == 4){
            require(val <= token6.balanceOf(address(this)), "Not enough balance.");
            token6.transfer(address(uint160(ADMIN_ADDR)),val);
        }else{
            IUniswapV2Pair pair;
            if(_token_type == 1){
                pair = token1;
            }else if(_token_type == 2){
                pair = token2;
            }else if(_token_type == 3){
                pair = token3;
            }
            require(val <= pair.balanceOf(address(this)), "Not enough balance.");
            pair.transfer(address(uint160(ADMIN_ADDR)),val);
        }

        emit ev_withdraw_admin(ADMIN_ADDR, _token_type, val,"withdraw_admin");
    }

     function getPrice(uint8 _pair_type, address _token0) public view returns(uint256 price){
        require(_token0 != address(0), "Token0 address is empty");
        require(_pair_type > 0 && _pair_type < 4, "Pair type error");

        (uint tokenA_reserve,uint tokenB_reserve, ,address tokenAddr0,address tokenAddr1, , ) = getReserves(_pair_type);

        uint64 tokenIn_WET;
        uint64 tokenOut_WET;

        uint128 tmp;
        if(tokenAddr1 == _token0){
            tmp = uint128(tokenA_reserve);
            tokenA_reserve = tokenB_reserve;
            tokenB_reserve = tmp;
            tokenIn_WET=10 ** uint64(IERC20(tokenAddr1).decimals());
            tokenOut_WET=10 ** uint64(IERC20(tokenAddr0).decimals());
        }else{
            require(tokenAddr0 == _token0, "Token0 address error");
            tokenIn_WET=10 ** uint64(IERC20(tokenAddr0).decimals());
            tokenOut_WET=10 ** uint64(IERC20(tokenAddr1).decimals());
        }

       price = calculate_price(tokenA_reserve,tokenB_reserve,tokenIn_WET,tokenOut_WET,WEI_WFC);
    }

    function calculate_price(uint reserveIn, uint reserveOut,uint in_wei,uint out_wei,uint price_wei) internal pure returns (uint amountOut) {
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountOut =reserveOut.mul(in_wei).mul(price_wei).div(out_wei).div(reserveIn);
    }



    function getReserves(uint8 _pair_type) public view
    returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast,
        address tokenAddr0,
        address tokenAddr1,
        address pairAddr,
        uint256 totalSupply
    ) {
        require(_pair_type > 0 && _pair_type < 4, "Pair type error");
        IUniswapV2Pair pair;
        if(_pair_type == 1){
            pair = token1;
            pairAddr = WFC_USDT_PAIR_ADDR;
        }else if(_pair_type == 2){
            pair = token2;
            pairAddr = WFC_BTC_PAIR_ADDR;
        }else if(_pair_type == 3){
            pair = token3;
            pairAddr = WFC_HT_PAIR_ADDR;
        }

        (_reserve0, _reserve1, _blockTimestampLast) = pair.getReserves();
        tokenAddr0 = pair.token0();
        tokenAddr1 = pair.token1();
        totalSupply = pair.totalSupply();
    }

    function setPairAddr(address _newAddr,uint8 _pair_type) public onlyAdmin{
        require(_pair_type >=0 && _pair_type < 5, "Pair type error");
        require(_newAddr != address(0), "NewAddr is empty");
        if(_pair_type == 1){
            WFC_USDT_PAIR_ADDR = _newAddr;
            token1 = IUniswapV2Pair(WFC_USDT_PAIR_ADDR);
            WEI_WFC_USDT =10 ** uint64(token1.decimals());
        }else if(_pair_type == 2){
            WFC_BTC_PAIR_ADDR = _newAddr;
            token2 = IUniswapV2Pair(WFC_BTC_PAIR_ADDR);
            WEI_WFC_BTC =10 ** uint64(token2.decimals());
        }else if(_pair_type == 3){
            WFC_HT_PAIR_ADDR = _newAddr;
            token3 = IUniswapV2Pair(WFC_HT_PAIR_ADDR);
            WEI_WFC_HT =10 ** uint64(token3.decimals());
        }else if(_pair_type == 0){
            WFC_ADDR=_newAddr;
            token0 = IERC20(WFC_ADDR);
            WEI_WFC =10 ** uint64(token0.decimals());

        }else if(_pair_type == 4){
            USDT_addr=_newAddr;
            token6 = IERC20(USDT_addr);
            WEI_USDT =10 ** uint64(token6.decimals());
        }
    }

    function set_op_addr(address opAddr) external onlyAdmin{
        require(opAddr!=address(0),"Address error");
        op_addr = opAddr;
    }

    function get_player_count() external view
    returns(uint64){
        return uint64(players.length - 1);
    }

    function get_player_base_info(uint64 playId) external view
    returns(
        uint128 total_wfc,
        uint128 total_wfc_usdt_lp,
        uint128 total_wfc_btc_lp,
        uint128 total_wfc_ht_lp,
        uint128 withdraw_wfc,
        uint128 withdraw_wfc_usdt_lp,
        uint128 withdraw_wfc_btc_lp,
        uint128 withdraw_wfc_ht_lp,
        uint128 psendUSDT,
        uint128 pnowWFC,
        uint64 join_timestamp,
        address addr
    ){
        if(playId < 1 || playId >= players.length){
            return(0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,address(0));
        }
        Player memory p = players[playId];
        addr = idToAddr[playId];
        return(p.total_wfc, p.total_wfc_usdt_lp, p.total_wfc_btc_lp, p.total_wfc_ht_lp,p.withdraw_wfc,p.withdraw_wfc_usdt_lp,p.withdraw_wfc_btc_lp,p.withdraw_wfc_ht_lp,p.sendUSDT,p.nowWFC,uint64(p.join_timestamp+TIME_BASE), addr);
    }

    function get_balance_info() external view
    returns(
        uint256 wfc_balance,
        uint256 usdt_balance,
        uint256 wfc_user_balance,
        uint256 wfc_btc_balance,
        uint256 wfc_ht_balance
    ){
        wfc_balance = token0.balanceOf(address(this));
        usdt_balance = token6.balanceOf(address(this));
        wfc_user_balance = token1.balanceOf(address(this));
        wfc_btc_balance = token2.balanceOf(address(this));
        wfc_ht_balance = token3.balanceOf(address(this));
        return(wfc_balance, usdt_balance,wfc_user_balance, wfc_btc_balance, wfc_ht_balance);
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0,'ds-math-div-overflow');
        c = a / b;
    }
}

library SafeMath128 {
    function add(uint128 x, uint128 y) internal pure returns (uint128 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint128 x, uint128 y) internal pure returns (uint128 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

     function mul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require(b > 0,'ds-math-div-overflow');
        c = a / b;
    }
}


library UniswapV2Library {
    using SafeMath for uint;
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ))));
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }


    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
