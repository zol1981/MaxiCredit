pragma solidity >=0.4.25;

contract SimpleTokenInterface {
    function allowance(address _from, address _to) public view returns(uint);
    function transfer(address _to, uint _sum) public;
    function transferFrom(address _from, address _to, uint _sum) public;//Should use ERC20 like transferFrom to direct tansfer
    function getTokenBalance(address _owner) public view returns(uint);
    function transferLoan(address _to, uint _sum, uint _interestRate) public;
}   

contract TestUsersInterface {
    function getUserPublicData(uint _id) public view returns(uint, uint);
    function checkUserPersonalID(uint _personalID) public view returns(bool);
    function checkUsersAddress(address _usersAddress) public view returns(bool);
    function getUsersAddress(uint _usersId, uint _counter) public view returns(address);
    function getUserByAddress(address _addr) public view returns(uint);
    function increaseCreditScore(uint _borrowerId, uint _plus, uint _creditId) public;
    function setCreditContractAddress(address _creditAddr, uint _userId, uint _loanId) public;
}

contract TestCreditContract {
    
    address SimpleTokenAddress = 0x5e12A8Ed676aa9Ce6B402B848BaD14E282b6C215;
    SimpleTokenInterface sti = SimpleTokenInterface(SimpleTokenAddress);
    TestUsersInterface tui = TestUsersInterface(0x3Ce63E7F60caDF49F9765c0d4e9359a7eC948900);
    
    uint public loanId;
    uint public lenderId;
    address public owner;
    uint public borrowerId;
    uint public periods;
    uint public length;
    uint[] public loanExpiration; //DONT USE ZERO ELEMENT
    bool[] public paidBack; //DONT USE ZERO ELEMENT
    uint public start;
    uint public lastReedem = 0;
    uint public toPayBack;
    uint public a;
    uint public capital;
    uint public initialCapital;
    uint public interestRate;
    uint public salesPrice;
    bool public toSale;
    address public server;
    
    constructor(uint _loanId, uint _lenderId, uint _borrowerId, uint _capital, uint _interestRate, uint _period, uint _redeem, uint _length, address _server) public {
        loanId = _loanId;
        lenderId = _lenderId;
        owner = tui.getUsersAddress(lenderId, 0);
        borrowerId = _borrowerId;
        capital = _capital;
        initialCapital = _capital;
        interestRate = _interestRate;
        start = now;
        periods = _period;
        length = _length;
        a = length / periods;
        for(uint i = 0; i <= _period; i++) {
            loanExpiration.push(a * i + now);
            paidBack.push(false);
        }
        toPayBack = _redeem;
        server = _server;
        toSale = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyServer() {
        require(msg.sender == server);
        _;
    }
    
    function setToRedeemed(uint _changeCapital) public onlyServer {
        lastReedem ++;
        paidBack[lastReedem] = true;
        capital -= _changeCapital;
        if(lastReedem == (periods - 1)) {
            toPayBack = capital * (100 + interestRate) / 100;
        }
        if(lastReedem == periods) {
            tui.increaseCreditScore(borrowerId, interestRate + 2, loanId);
        }
    }
    
    function getLoanID() public onlyServer view returns(uint) {
        return loanId;
    }
    
    //function getLoanOwner() public {}
    
    //Get initial capital,  interest rate, periods, redeem, length, start
    function getLoanInitialDetails() public view returns(uint, uint, uint, uint, uint, uint) {
        return(initialCapital, interestRate, toPayBack, periods, length, start);
    }
    
    //Get current capital, last redeem
    function getCurrentDetails() public view returns(uint, uint) {
        return(capital, lastReedem);
    }
    
    function getAllDetails() public view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return(loanId, initialCapital, interestRate, toPayBack, periods, length, start, capital, lastReedem);
    }
    
    function setToSale(uint _price) public onlyOwner {
        salesPrice = _price; //in Maxit
        toSale = true;
    }
    
    function deleteSale() public onlyOwner {
        toSale = false;
    }
    
    function buyCreditContract() public payable {
        require(toSale == true);
        require(msg.value == salesPrice);
        toSale = false;
        sti.transfer(owner, salesPrice);
        owner = msg.sender;
    }
    
    function transferCreditContract(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    //??? PERIODS
    function setRabat(uint _changeCapital, uint _changeInterest) public onlyOwner {
        require(_changeCapital <= capital);
        require(_changeInterest <= interestRate);
        capital -= _changeCapital;
        interestRate -= _changeInterest;
        uint remainingPeriods = periods - lastReedem; 
        toPayBack = calcReedem(capital, remainingPeriods, interestRate);
    }
    
    function reStructure(uint _period) public onlyOwner {
        require(_period > periods);
        uint remainingPeriods = _period - lastReedem;
        toPayBack = calcReedem(capital, remainingPeriods, interestRate);
    }
    
    //Reusable, should move to library
    function calcReedem (uint _amount, uint _period, uint _rate) private pure returns(uint) { 
        uint pow = 1;
        uint onePerPow = 1000000000000;
        uint ratePlus = _rate + 100;
        if(_period == 1) {
            pow *= ratePlus * 100;
        } else {
            for(uint i = 1; i <= _period; i++) {
                pow *= ratePlus;
                if(i > 2) {
                    pow /= 100; 
                }
            }
        }
        onePerPow /= pow;
        uint oneMinus = 100000000 - onePerPow;
        uint currentRedeem = uint(_amount * _rate * 1000000 / oneMinus);
        return(currentRedeem);
    }
    
    /*   
    function getBorrower() public {
        tui.getUsersAddress[borrowerId];   
    }
    */
}
