pragma solidity >=0.4.25;
import "./TestCreditAgreement.sol";

contract TestUsersInterface {
    function registerUser(string _firstName, uint _birthDate, string _mothersFirstName, uint _idDocumentNumber,
        uint _personalID, string _residentalAddress, string _emailAddress, uint _phoneNumber) public;
    function getUserByID1(uint _id) public view returns(string, uint, string, uint, uint);
    function getUserByID21(uint _id) public view returns(string, string, uint, uint);
    function checkUserPersonalID(uint _personalID) public view returns(bool);
    function checkUsersAddress(address _usersAddress) public view returns(bool);
    function getUsersAddress(uint _usersId) public view returns(address);
    function getUserByAddress(address _addr) public view returns(uint);
}

contract AgreementInterface {
    function setToRedeemed() public;
}

//Last updated by Zol, 2019.02.02

contract TestCredit {
    
    event CreditOfferCreated(uint indexed _creditOfferCounter, uint indexed _lendersId, uint _loanAmount, uint _loanType, uint _loanLength, uint _interestRate);
    event CreditClaimCreated(uint indexed _creditOfferCounter, uint indexed _borrowersId, uint _loanAmount, uint _loanType, uint _loanLength, uint _interestRate);
    
    address public contractOwner;
    address MC2Address = 0x0DC66D99267b102A525f82801E252835A87d097d;
    address SimpleTokenAddress = 0x5e12A8Ed676aa9Ce6B402B848BaD14E282b6C215;
    SimpleTokenInterface sti = SimpleTokenInterface(SimpleTokenAddress);
    
    TestUsersInterface tui = TestUsersInterface(0x89DA0C515FFABAaa90602B70d76a4434c4118750);
    
    address[] public serverAddress;
    mapping(address => bool) public isMCServer;
    
    struct CreditOffer {
        address lendersAddress;
        uint lendersId;
        uint loanAmount;
        uint loanType;
        uint loanLength;
        uint periodNumber;
        uint interestRate;
        uint minCreditScore;
        uint offerLastTo;
    }
    CreditOffer[] public creditOffers;
    uint public creditOfferCounter = 0;
    
    struct CreditClaim {
        address borrowersAddress;
        uint borrowersId;
        uint loanAmount;
        uint loanType;
        uint loanLength;
        uint periodNumber;
        uint interestRate;
        uint borrowersCreditScore;
        uint claimLastTo;
    } 
    CreditClaim[] public creditClaims;
    uint public creditClaimCounter = 0;
    
    address public newCredit;
    address[] public Credits;
    uint[][] public creditsByExpiration; //public helyett inkább majd getter function kell
    uint public creditCounter = 0;
    
    constructor () public {
        contractOwner = msg.sender;
    }
    
    modifier onlyOwnerOf(uint _userId) {
        require(tui.getUserByAddress(msg.sender) == _userId);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }
    
    modifier onlyServer() {
        require(isMCServer[msg.sender] == true);
        _;
    }
    
    function setServer(address _addr) public onlyOwner {
        require(_addr != address(0));
        serverAddress.push(_addr);
        isMCServer[_addr] = true;
    }
    
    function modifyServer(address _addr, uint _id) public onlyOwner {
        require(_addr != address(0));
        isMCServer[serverAddress[_id]] = false;
        serverAddress[_id] = _addr;
        isMCServer[_addr] = true;
    }
    
    function getBalance(address _addr) public view returns(uint) {
        return(sti.getTokenBalance(_addr));
    }
    
    function createCreditOffer(uint _loanAmount, uint _loanType, uint _loanLength, uint _periodNumber, uint _interestRate, uint _minCreditScore, uint _lastTo) public {
        //require(isUserPersonalID[_lendersId] == true);
        require(sti.getTokenBalance(msg.sender) >= _loanAmount);
        require(sti.allowance(msg.sender, this) >= _loanAmount);
        uint creditOfferLastTo = now + _lastTo;
        uint lendersId = getSenderId(msg.sender);
        creditOffers.push(CreditOffer(msg.sender, lendersId, _loanAmount, _loanType, _loanLength, _periodNumber, _interestRate, _minCreditScore, creditOfferLastTo));
        creditOfferCounter ++;
        sti.transferFrom(msg.sender, this, _loanAmount);
        emit CreditOfferCreated(creditOfferCounter, lendersId, _loanAmount, _loanType, _loanLength, _interestRate);
    }
    
    function createCreditClaim(uint _loanAmount, uint _loanType, uint _loanLength, uint _periodNumber, uint _interestRate, uint _lastTo) public {
        uint toAllowAmount = _loanAmount + (_loanAmount * _interestRate / 100);
        require(sti.allowance(msg.sender, this) >= toAllowAmount); 
        uint creditClaimersId = getSenderId(msg.sender);
        uint creditScoreOfTheClaimer;
        (,,,creditScoreOfTheClaimer)= tui.getUserByID21(creditClaimersId);
        uint creditClaimLastTo = now + _lastTo;
        creditClaims.push(CreditClaim(msg.sender, creditClaimersId, _loanAmount, _loanType, _loanLength, _periodNumber, _interestRate, creditScoreOfTheClaimer, creditClaimLastTo));
        creditClaimCounter ++;
        //allow funds for redeems   
        //end time of CreditClaim?
        //event
    }

    function getSenderId(address _addr) public view returns(uint) {
        uint claimerId = tui.getUserByAddress(_addr);
        return(claimerId);
    }
    
    function getSenderCreditScore(address _addr) public view returns(uint) {
        uint claimerIdCreditScore;
        (,,,claimerIdCreditScore) = tui.getUserByID21(tui.getUserByAddress(_addr));    
        return(claimerIdCreditScore);
    }
    
    //Minimum credit amount is 200
    function acceptCreditOffer(uint _offerId, uint _amount) public {
        uint paybacksInterest = uint(_amount * creditOffers[_offerId].interestRate / 100); 
        uint payback = _amount + paybacksInterest;
        uint expiration = now + creditOffers[_offerId].loanLength;
        uint lender = creditOffers[_offerId].lendersId;
        address lenderAddress = creditOffers[_offerId].lendersAddress;
        
        require(sti.allowance(msg.sender, this) >= payback);

        uint claimerId = getSenderId(msg.sender);
        uint claimerIdCreditScore = getSenderCreditScore(msg.sender);        
        require(claimerIdCreditScore >= creditOffers[_offerId].minCreditScore);
        require(creditOffers[_offerId].loanAmount >= _amount);
        uint amountToBorrower = _amount * 995 / 1000;
        uint amountToMC2 = _amount * 5 / 1000;
        sti.transferLoan(msg.sender, amountToBorrower, creditOffers[_offerId].interestRate);
        sti.transfer(MC2Address, amountToMC2);
        creditOffers[_offerId].loanAmount -= _amount;

        newCredit = new TestCreditAgreement(creditCounter, lender, lenderAddress, claimerId, _amount, paybacksInterest, expiration, this);
        creditCounter = Credits.push(newCredit);
        //event
     //   creditsByExpiration[expiration][creditCounter]; not working
    }
    
    //Minimum credit amount is 200
    function acceptCreditClaim(uint _claimId, uint _amount) public {
        require(sti.allowance(msg.sender, this) >= _amount);
        require(creditClaims[_claimId].loanAmount >= _amount);
        uint creditor = getSenderId(msg.sender);
        uint creditReceiverId = creditClaims[_claimId].borrowersId;
        uint paybacksInterest = uint(creditClaims[_claimId].interestRate * _amount / 100);
        uint expiration = now + creditClaims[_claimId].loanLength;
        uint amountToBorrower = _amount * 995 / 1000;
        uint amountToMC2 = _amount * 5 / 1000;
        sti.transferFrom(msg.sender, this, _amount);
        sti.transferLoan(creditClaims[_claimId].borrowersAddress, amountToBorrower, creditClaims[_claimId].interestRate);
        sti.transfer(MC2Address, amountToMC2);
        creditClaims[_claimId].loanAmount -= _amount;
        
        newCredit = new TestCreditAgreement(creditCounter, creditor, msg.sender, creditReceiverId, _amount, paybacksInterest, expiration, this);
        creditCounter = Credits.push(newCredit);
        //event
    }
    
    function redeem(uint _creditId) public onlyServer {
        TestCreditAgreement credit = TestCreditAgreement(Credits[_creditId]);
        AgreementInterface ncredit = AgreementInterface(Credits[_creditId]);
        require(now >= credit.loanExpiration());
        address borrower = tui.getUsersAddress(credit.borrowerId()); 
        uint paybackInterest = credit.interest();
        uint paybackAmount = paybackInterest + credit.capital();
        //sti.transferFrom(borrower, paybackAmount); //can use ERC20 like transferFrom to transfer direct to lender and MC2
        address ownerOfLendingContract = credit.owner();
        uint MC2Part = paybackInterest / 10;
        uint ownerRedeemPart = paybackAmount - MC2Part;
        sti.transferFrom(borrower, ownerOfLendingContract, ownerRedeemPart);
        sti.transferFrom(borrower, MC2Address, MC2Part);
        ncredit.setToRedeemed();
        paybackAmount = 0;
        //event
    }
}
