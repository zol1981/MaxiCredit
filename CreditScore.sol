pragma solidity >=0.4.25;

contract CreditScore {
    uint public creditScoreChange;
    uint[] limits = [20, 100, 500, 1000];
    
    function calculateScore(uint _interest) public {
        if(_interest <= limits[0]) {
            creditScoreChange = _interest;
        } else if(_interest <= limits[1]) {
            creditScoreChange = limits[0] + (_interest - limits[0]) / 2;
        } else if(_interest <= limits[2]) {
            creditScoreChange = 60 + (_interest - limits[1]) / 4;
        } else if(_interest <= limits[3]) {
            creditScoreChange = 160 + (_interest - limits[2]) / 8;
        } else {
            creditScoreChange = 223 + (_interest - limits[3]) / 16;
        }
        
    }
}
