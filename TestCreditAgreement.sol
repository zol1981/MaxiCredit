pragma solidity ^0.4.25;

contract SimpleTokenInterface {
    function allowance(address _from, address _to) public view returns(uint);
    function transfer(address _to, uint _sum) public;
    function transferFrom(address _from, address _to, uint _sum) public;//Should use ERC20 like transferFrom to direct tansfer
    function getTokenBalance(address _owner) public view returns(uint);
    function transferLoan(address _to, uint _sum, uint _interestRate) public;
}    

contract TestCreditAgreement {
    
    address SimpleTokenAddress = 0x5e12A8Ed676aa9Ce6B402B848BaD14E282b6C215;
    SimpleTokenInterface sti = SimpleTokenInterface(SimpleTokenAddress);
    
    uint public loanId;
    uint public lenderId;
    address public owner;
    uint public borrowerId;
    uint public capital;
    uint public interest;
    uint public loanExpiration;
    uint public toPayBack;
    address public server;
    
    constructor(uint _loanId, uint _lenderId, address _owner, uint _borrowerId, uint _capital, uint _interest, uint _loanExpiration, address _server) public {
        loanId = _loanId;
        lenderId = _lenderId;
        owner = _owner;
        borrowerId = _borrowerId;
        capital = _capital;
        interest = _interest;
        loanExpiration = _loanExpiration;
        toPayBack = capital + interest;
        server = _server;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyServer() {
        require(msg.sender == server);
        _;
    }
    
    function setToRedeemed() public onlyServer {
        toPayBack = 0;
    }
    
    function getLoanID() public onlyServer view returns(uint) {
        return loanId;
    }
    
    function sellCreditAgreement(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
