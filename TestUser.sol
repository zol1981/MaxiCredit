pragma solidity >=0.4.25;
//import "./OnlyServer.sol";

contract TestUsers {
    
    event NewUserAdded(string _firstName, uint indexed _userCounter, address indexed _address, uint _personalID);
    
    mapping(uint => bool) isUserPersonalID; 
    mapping(uint => mapping(uint => address)) usersAddresses; 
    mapping(uint => address) addressToAdd;
    mapping(address => uint) userByAddress; 
    mapping(address => bool) isUsersAddress; 
    mapping(uint => mapping(address => bool)) isSpec;
    
    struct User { 
        string userName;
       // string lastName;
        uint userID;
        uint birthDate; //unix time + 70 years in seconds (70 * 365 + 17) * 24 * 60 * 60
        uint age;
        string mothersName;
    //    string mothersLastName;
        uint idDocumentNumber;
        uint personalID;
        string country;
        string city;
        string residentalAddress;
        string emailAddress;
        uint phoneNumber;
        uint creditScore;
        uint addressesCounter;
        uint creditContractCounter;
    }   
    
    User[] users;
    uint userCounter;
    
    address public owner;
    address public testCreditAddress;
    address public serversContract;
    mapping(uint => mapping(uint => address)) public creditContract; //User ID -> user's credit count -> credit address 
    mapping(address => uint) public creditContractAddress; //credit address -> loan ID
   // OnlyServer servers;
    
    constructor () public {
        owner = msg.sender;
        userCounter = 0;
        //     servers = new OnlyServer();
//        serversContract = address(servers);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /*
    modifier onlyServer() {
        require(servers.isServer(msg.sender));
        _;
    }
*/
    modifier onlySpec(uint _id) {
        require(isSpec[_id][msg.sender] == true);
        _;
    }
    
    modifier onlyTestCredit() {
        require(msg.sender == testCreditAddress);
        _;
    }
    
    modifier onlyCreditContract(uint _id) {
        require(creditContractAddress[msg.sender] == _id);
        _;
    }
     
    //Need done immediatly after deploy contract
    //First deploy this contract, then deploy TestCredit with this address, then run this with TestCredit's address
    function setTestCreditAddress(address _addr) public onlyOwner {
        testCreditAddress = _addr;
    }
    
    function setCreditContractAddress(address _creditAddr, uint _userId, uint _loanId) public onlyTestCredit() {
        creditContract[_userId][users[_userId].creditContractCounter] = _creditAddr;
        users[_userId].creditContractCounter ++;
        creditContractAddress[_creditAddr] = _loanId;
    }
    
    function registerUser(string memory _firstName,
        //string _lastName,
        uint _birthDate,
        string memory _mothersFirstName,
        //string _mothersLastName,
        uint _idDocumentNumber,
        uint _personalID,
        string memory _country,
        string memory _city,
        string memory _residentalAddress,
        string memory _emailAddress,
        uint _phoneNumber) public {
            require(isUserPersonalID[_personalID] != true);
            require(isUsersAddress[msg.sender] != true);
            isUserPersonalID[_personalID] = true;  
            isUsersAddress[msg.sender] = true;
            usersAddresses[userCounter][0] = msg.sender;
            userByAddress[msg.sender] = userCounter;
            isSpec[userCounter][owner] = true; //??
            isSpec[userCounter][testCreditAddress] = true; //??
            isSpec[userCounter][msg.sender] = true;
            users.push(User(_firstName, userCounter, _birthDate, getAge(_birthDate), _mothersFirstName, _idDocumentNumber, _personalID, _country, _city, _residentalAddress, _emailAddress, _phoneNumber, 100, 1, 0));
            emit NewUserAdded(_firstName, userCounter, msg.sender, _personalID);
            userCounter ++;
    }
    
    function setAddressToAdd(address _add) public {
        require(isUsersAddress[msg.sender] == true);
        addressToAdd[userByAddress[msg.sender]] = _add;
    }
    
    function addAddressToUser(uint _id) public {
        require(addressToAdd[_id] == msg.sender);
        usersAddresses[_id][users[_id].addressesCounter] = msg.sender;
        users[_id].addressesCounter ++;
        userByAddress[msg.sender] = _id;
        isUsersAddress[msg.sender] = true;
    }
    
    function getMyCredit(uint _counter) public view returns(address) {
        return(creditContract[getUserByAddress(msg.sender)][_counter]);
    }
    
    //CreditScore, address count, age, country
    function getUserPublicData(uint _id) public view returns(uint, uint, uint, string memory, string memory, uint) {
        return(users[_id].creditScore, users[_id].addressesCounter, users[_id].age, users[_id].country, users[_id].city, 
        users[_id].creditContractCounter);
    }
    
    //Name, birth date, mothers name, ID, personalID, residental address, email, phone number, 
    function getUserPrivateData1(uint _id) public view onlySpec(_id) returns(string memory, uint, string memory, uint, uint) {
        return(users[_id].userName, users[_id].birthDate, users[_id].mothersName, users[_id].idDocumentNumber, users[_id].personalID);
    }
    
    function getUserPrivateData2(uint _id) public view onlySpec(_id) returns(string memory, string memory, uint) {
        return(users[_id].residentalAddress, users[_id].emailAddress, users[_id].phoneNumber);
    }
    
    function checkUserPersonalID(uint _personalID) public view returns(bool) {
        return(isUserPersonalID[_personalID]);
    }
    
    function checkUsersAddress(address _usersAddress) public view returns(bool) {
        return(isUsersAddress[_usersAddress]);
    }
    
    function getUsersAddress(uint _usersId, uint _counter) public view returns(address) {
     /*   uint pi;
        (,,,,pi) = getUserPrivateData1(_usersId);
        require(isUserPersonalID[pi]); */
        return(usersAddresses[_usersId][_counter]);
    }
    
    function getUserByAddress(address _addr) public view returns(uint) {
        require(checkUsersAddress(_addr));
        //if fails error msg
        return(userByAddress[_addr]);
    }
    
    function getAge(uint _birthDate) private view returns(uint) {
        uint currentTime = now + (70 * 365 + 17) * 24 * 60 * 60;
        uint age = currentTime - _birthDate;
        return(age);
    }
    
    function increaseCreditScore(uint _borrowerId, uint _plus, uint _creditId) public onlyCreditContract(_creditId) {
        users[_borrowerId].creditScore += _plus;
    }
}
