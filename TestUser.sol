pragma solidity ^0.4.25;

contract TestUsers {
    
    event NewUserAdded(string _firstName, uint indexed _userCounter, address indexed _address, uint _personalID);
    
    mapping(uint => bool) isUserPersonalID; 
    mapping(uint => address) usersAddresses; 
    mapping(address => uint) userByAddress; 
    mapping(address => bool) isUsersAddress; 
    
    struct User { //inkább önálló contract legyen, hogy könnyen lehessen több ethereum címet tárolni
        string userName;
       // string lastName;
        uint userID;
        uint birthDate;
        string mothersName;
    //    string mothersLastName;
        uint idDocumentNumber;
        uint personalID;
        string residentalAddress;
        string emailAddress;
        uint phoneNumber;
        uint creditScore;
    }   
    User[] users;
    uint userCounter;
    
    address owner;
    
    constructor () public {
        owner = msg.sender;
        userCounter = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function registerUser(string _firstName,
        //string _lastName,
        uint _birthDate,
        string _mothersFirstName,
        //string _mothersLastName,
        uint _idDocumentNumber,
        uint _personalID,
        string _residentalAddress,
        string _emailAddress,
        uint _phoneNumber) public {
            require(isUserPersonalID[_personalID] != true);
            require(isUsersAddress[msg.sender] != true);
            isUserPersonalID[_personalID] = true;  
            isUsersAddress[msg.sender] = true;
            usersAddresses[userCounter] = msg.sender;
            userByAddress[msg.sender] = userCounter;
            users.push(User(_firstName, userCounter, _birthDate, _mothersFirstName, _idDocumentNumber, _personalID, _residentalAddress, _emailAddress, _phoneNumber, 100));
            emit NewUserAdded(_firstName, userCounter, msg.sender, _personalID);
            userCounter ++;
    }
    
    /*
    function addAddressToUser(uint _id) public {
        require(userByAddress[msg.sender] == _id);
        usersAddresses[_id][usersAddressesCounter] = msg.sender; //usersAddresses change to double mapping + create usersAddressesCounter variable
    }
    
    */
    
    //Should limit the access to user data
    function getUserByID1(uint _id) public view returns(string, uint, string, uint, uint) {
        return(users[_id].userName, users[_id].birthDate, users[_id].mothersName, users[_id].idDocumentNumber, users[_id].personalID);   
    }
    
    function getUserByID21(uint _id) public view returns(string, string, uint, uint) {
        return(users[_id].residentalAddress, users[_id].emailAddress, users[_id].phoneNumber, users[_id].creditScore);
    }
    
    function checkUserPersonalID(uint _personalID) public view returns(bool) {
        return(isUserPersonalID[_personalID]);
    }
    
    function checkUsersAddress(address _usersAddress) public view returns(bool) {
        return(isUsersAddress[_usersAddress]);
    }
    
    function getUsersAddress(uint _usersId) public view returns(address) {
        uint pi;
        (,,,,pi) = getUserByID1(_usersId);
        require(isUserPersonalID[pi]); 
        return(usersAddresses[_usersId]);
    }
    
    function getUserByAddress(address _addr) public view returns(uint) {
        require(checkUsersAddress(_addr));
        //if fails error msg
        return(userByAddress[_addr]);
    }
}
