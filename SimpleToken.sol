pragma solidity >=0.4.25;
import "./AddressUtils.sol";

//Last updated by Zol, 2019.01.20
contract ERC20Interface {
    function allowance(address _from, address _to) public view returns(uint);
    function transferFrom(address _from, address _to, uint _sum) public;
    function transfer(address _to, uint _sum) public;
    function balanceOf(address _owner) public view returns(uint);
}

contract SimpleToken {
    
    event Transfer(address indexed _from, address indexed _to, uint _sum);
    event CardOrderCreated(address indexed _buyer, uint indexed _orderId, uint _amount);
    event OrderPaid(address indexed _buyer, uint indexed _orderId);
    event TokenBought(address indexed _buyer, uint indexed _promoter, uint _sum);
    event TokenBoughtFromSeller(address indexed _buyer, address _seller, uint _amount, uint indexed _offerId);
    event SetToSale(address indexed _seller, uint indexed _offerId, uint _amount, uint _unitPrice);
    event ApproveTransfer(address indexed _seller, address indexed _buyer, uint _amount);
    event TxApproval(address indexed _from, address indexed _to, uint _sum, uint _id);
    
    using AddressUtils for address;
    uint public initSupply;
    uint supply;
    uint decimals;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public orderByAddress;
    mapping(uint => address) public orderById;
    mapping(uint => bool) public orderPaid;
    uint[] public orderAmountById;
    uint orderId = 0;
    
    mapping(address => uint) public saleOffersByAddress;
    mapping(uint => address) public saleOffersById;
    uint public saleOffersCounter = 0;
    mapping(uint => uint) public saleOffersAmount;
    mapping(uint => uint) public saleOffersUnitPrice;
    
    mapping(address => mapping(address => uint)) public approvedTransfers;
    
    string public name;
    string public symbol;
    address public contractOwner;
    address public operatorOfContract;
    
    address[] serverAddress;
    uint serverAddressArrayLength;
    mapping(address => bool) isOurServer;
    
    uint public initPriceUSD; //USD cent
    uint public initPriceETH; 

    modifier onlyServer() {
        require(isOurServer[msg.sender] == true);
        _;
    }
    
    modifier operator() {
        require(msg.sender == operatorOfContract);
        _;
    }
    
   struct ToTransfer {
       address tokenFrom;
       address tokenTo;
       uint tokenAmount;
    }
    
    ToTransfer[] toTransfers;
    uint public toTransferCounter = 0;
    
    constructor (address _operator, uint _initSupply, string _name, string _symbol, address _serverAddress, uint _initPriceUSD, uint _initPriceETH) public {
        operatorOfContract = _operator;        
        balanceOf[this] = _initSupply;
        initSupply = _initSupply;
        supply = initSupply;
        name = _name;
        symbol = _symbol;
        serverAddressArrayLength = serverAddress.push(_serverAddress);
        isOurServer[_serverAddress] = true;
        initPriceUSD = _initPriceUSD;
        initPriceETH = _initPriceETH;
    }
    
    function totalSupply() public view returns(uint) {
        return(supply);
    }
    
    function mintByTx(uint _txAmount) private {
        uint supplyIncrease = uint(_txAmount * 2 / 100);
        supply += supplyIncrease;
        balanceOf[this] += supplyIncrease;
    }
    
    function mintByCredit(uint _loanAmount, uint _interestRate) private {
        /*
        if(_interestRate <= 100) {
            uint supplyIncrease = uint(_loanAmount * _interestRate / 100);
        } else {
           uint supplyIncrease = uint(_loanAmount); 
        }
        */
        uint supplyIncrease = uint(_loanAmount * _interestRate / 100); //SHOULD limit and use mintByRedeem
        supply += supplyIncrease;
        balanceOf[this] += supplyIncrease;
    }
    
    /*
    function mintByRedeem(uint _loanAmount, uint _interestRate) private {
        require(_interestRate > 100)
        uint supplyIncrease = uint((_loanAmount * (_interestRate - 100)) / 100);
        supply += supplyIncrease;
        balanceOf[this] += supplyIncrease;
    }
    */
    
    function withdrawERC20(address _erc20Address, address _to, uint _amount) public operator {
        require(_erc20Address != address(0) && _to != address(0));
        ERC20Interface ei = ERC20Interface(_erc20Address);
        ei.transfer(_to, _amount);
    }
    
    function withdrawETH(address _to, uint _amount) public operator {
        require(_to != address(0));
        _to.transfer(_amount);
    }
    
    function setServerAddress(address _serverAddress) public operator {
        serverAddressArrayLength = serverAddress.push(_serverAddress);
        isOurServer[_serverAddress] = true;
    }
    
    function getServerAddressLength() public view operator returns(uint) {
        return serverAddressArrayLength;
    }
    
    function getServerAddress(uint _num) public view operator returns(address) {
        return serverAddress[_num];
    }
    
    function _transfer(address _from, address _to, uint _sum) private {
        require(_from != address(0));
        require(_to != address(0));
        require(_from != _to);
        require(_sum > 0);
        require(balanceOf[_from] >= _sum);
        require(balanceOf[_to] + _sum >= _sum);
        uint sumBalanceBeforeTx = balanceOf[_from] + balanceOf[_to]; 
        balanceOf[_from] -= _sum;
        balanceOf[_to] += _sum;
        assert(sumBalanceBeforeTx == balanceOf[_from] + balanceOf[_to]);
        mintByTx(_sum);
        emit Transfer(_from, _to, _sum);
    }
    
    function transfer(address _to, uint _sum) public {
        _transfer(msg.sender, _to, _sum);
    }
    /*
    Using function overload
    function transfer(address _to, uint _sum, uint _interestRate, bool _isRedeem) public {
        _transfer(msg.sender, _to, _sum);
        if(!_type) {
            mintByCredit(_sum, _interestRate);    
        }
        if(_interestRate > 100 && _type) {
           mintByRedeem(_sum, _interestRate); 
        }
    }
    */
    function transferLoan(address _to, uint _sum, uint _interestRate) public {
        _transfer(msg.sender, _to, _sum);
        mintByCredit(_sum, _interestRate);
    }
    
    //For using other currencies like BTC, fiat...
    function createOuterOrder(uint _amount) public {
        require(_amount > 0);
        orderAmountById.push(_amount);
        orderByAddress[msg.sender] = orderId;
        orderById[orderId] = msg.sender;
        emit CardOrderCreated(msg.sender, orderId, _amount);
        orderId ++;
    }
    
    function setOuterOrderPaid(uint _orderId, uint _paidAmount) public onlyServer {
        uint orderSum = orderAmountById[_orderId] * initPriceUSD;
        require(orderSum == _paidAmount);
        orderPaid[_orderId] = true;
        address buyerAddress = orderById[_orderId];
        emit OrderPaid(buyerAddress, _orderId);
    }
    
    function outerTransfer(uint _orderId) public {
        require(orderPaid[_orderId] == true);
        _transfer(this, msg.sender, orderAmountById[_orderId]);
    }
    //----------
    
    function buyToken(uint _sum, uint _promoter) public payable {
        uint price = _sum * initPriceETH;
        require(msg.value == price);
        _transfer(this, msg.sender, _sum);
        emit TokenBought(msg.sender, _promoter, _sum);
    }
    
    function getTokenBalance(address _owner) public view returns(uint) {
        return(balanceOf[_owner]);
    }
    
    function setToSale(uint _amount, uint _unitPrice) public {
        require(balanceOf[msg.sender] >= _amount);
        require(_unitPrice > 0);
        saleOffersByAddress[msg.sender] = saleOffersCounter;
        saleOffersById[saleOffersCounter] = msg.sender;
        saleOffersAmount[saleOffersCounter] = _amount;
        saleOffersUnitPrice[saleOffersCounter] = _unitPrice;
        emit SetToSale(msg.sender, saleOffersCounter, _amount, _unitPrice);
        saleOffersCounter ++;
    }
    
    function buyFromSeller(uint _amount, uint _offerId) public payable {
        require(saleOffersAmount[_offerId] >= _amount);
        uint orderPrice = _amount * saleOffersUnitPrice[_offerId];
        require(msg.value == orderPrice);
        saleOffersAmount[_offerId] -= _amount;
        _transfer(saleOffersById[_offerId], msg.sender, _amount);
        uint sellersShare = orderPrice * 99 / 100;
        uint toSend = sellersShare;
        sellersShare = 0;
        saleOffersById[_offerId].transfer(toSend);
        emit TokenBoughtFromSeller(msg.sender, saleOffersById[_offerId], _amount, _offerId);
    }
    
    function approveTx(address _to, uint _sum) public {
        toTransfers.push(ToTransfer(msg.sender, _to, _sum));
        emit TxApproval(msg.sender, _to, _sum, toTransferCounter);
        toTransferCounter ++;
    }
    
    function getApprovedTx(uint _id) public view returns(address, address, uint) {
        return(toTransfers[_id].tokenFrom, toTransfers[_id].tokenTo, toTransfers[_id].tokenAmount);
    }
    
    function transferById(uint _transferId) public {
        _transfer(toTransfers[_transferId].tokenFrom, toTransfers[_transferId].tokenTo, toTransfers[_transferId].tokenAmount);
        toTransfers[_transferId].tokenAmount = 0;
    }
    
    function transferByIdPartly(uint _transferId, uint _amount) public {
        require(toTransfers[_transferId].tokenAmount >= _amount);
        _transfer(toTransfers[_transferId].tokenFrom, toTransfers[_transferId].tokenTo, _amount);
        toTransfers[_transferId].tokenAmount -= _amount;
    }
    
    
    function approve(address _spender, uint _sum) public {
        approvedTransfers[msg.sender][_spender] += _sum;
        emit ApproveTransfer(msg.sender, _spender, _sum);
    }
    
    function allowance(address _from, address _to) public view returns(uint) {
        return (approvedTransfers[_from][_to]);
    }
    
    function transferFrom(address _from, address _to, uint _sum) public {
        require(approvedTransfers[_from][msg.sender] >= _sum);
        approvedTransfers[_from][msg.sender] -= _sum;
        _transfer(_from, _to, _sum);
    }
}
