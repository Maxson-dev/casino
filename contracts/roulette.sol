// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils.sol";
import "./chip.sol";


struct RouletteConfig {
    uint timeForBets;
    address croupier;
    address casino;
}

contract Roulette is Ownable {

    using SignedMath8 for int8;

    event RoundEnded(uint _roundId, uint _winNum);
    event NoMoreBets(uint _roundId);

     struct Bet {
        uint payout;
        uint size;
        uint8[] nums;
    }

    // gambler => (round => bet)
    mapping (address => mapping(uint => Bet)) private bets;
    // round => winNum
    mapping (uint => uint) public winNums;

    Chip private cashDesk;
    
    uint public timeForBets;
    uint public startBettingTime;

    uint public minBetSize;
    uint public maxBetSize;

    uint public currentRound;
    bool public roundStarted;

    address public croupier;

    address public casinoContract; 

    constructor(RouletteConfig memory config) 
    {
        timeForBets = config.timeForBets;
        croupier = config.croupier;
        casinoContract = config.casino;
    }

    modifier onlyCroupier() {
        require(msg.sender == croupier);
        _;
    }

    modifier validBet(uint8[] calldata _nums, uint _size) {
        require(!roundStarted);
        require(_size >= minBetSize && _size <= maxBetSize);
        uint len = _nums.length;
        require(len <= 18);
        for (uint i = 0; i < len;) {
            uint8 n = _nums[i];
            require(n >= 0 && n <= 36, "invalid bet!");
            unchecked {
                ++i;
            }
        }
        _;
    }


    function setTimeForBets(uint _time) external onlyOwner {
        timeForBets = _time;
    }

    function setMinSize(uint _min) external onlyOwner {
        minBetSize = _min;
    }

    function setMaxSize(uint _max) external onlyOwner {
        maxBetSize = _max;  
    }

    function claimRouletteRewards(uint[] calldata _rounds) external {
        for (uint i = 0; i < _rounds.length;) {
            uint round = _rounds[i];
            //require();
            unchecked {
                ++i;
            }
        }
    }

    // INTERNAL BETS
    function betStraight(uint8[] calldata _nums, uint _size) 
        external 
        validBet(_nums, _size) 
    {
        require(_nums.length == 1);

        Bet memory bet = Bet(35, _size, _nums);
        _placeInsideBet(bet);
    }

    function betSplit(uint8[] calldata _nums, uint _size) 
        external
        validBet(_nums, _size) 
    {
        require(_nums.length == 2);
        int8 a = int8(_nums[0]);
        int8 b = int8(_nums[1]);

        // only neighboring numbers except zero
        require(a > 0 && b > 0);
        require( (a-b).abs() == 1 || (a-b).abs() == 3);

        Bet memory bet = Bet(17, _size, _nums);
        _placeInsideBet(bet);
    }

    function betStreet(uint8[] calldata _nums, uint _size)
        external
        validBet(_nums, _size) 
    {
        require(_nums.length == 3);

        uint8 a = _nums[0];
        uint8 b = _nums[1];
        uint8 c = _nums[2];

        require(b - a == 1 && c - b == 1);

        Bet memory bet = Bet(11, _size, _nums);
        _placeInsideBet(bet);
    }

    function betCorner(uint8[] calldata _nums, uint _size)
        external
        validBet(_nums, _size) 
    {
        require(_nums.length == 4);

        uint8 a = _nums[0];
        uint8 b = _nums[1];
        uint8 c = _nums[2];
        uint8 d = _nums[3];

        require(b - a == 1 
             && c - b == 2 
             && d - c == 1);
             
        Bet memory bet = Bet(8, _size, _nums);
        _placeInsideBet(bet);
    }

    function betDoubleStreet(uint8[] calldata _nums, uint _size)
        external
        validBet(_nums, _size) 
    {
        require(_nums.length == 6);
        for (uint i; i < 6;) {
            if (i == 0) continue;
            require(_nums[i] - _nums[i-1] == 1);
            unchecked {
                ++i;
            }
        }
        Bet memory bet = Bet(5, _size, _nums);
        _placeInsideBet(bet);
    }

    function betBasket(uint8[] calldata _nums, uint _size)
        external
        validBet(_nums, _size)
    {
        require(_nums.length == 3);
        require( (_nums[0] == 0 && _nums[1] == 1 && _nums[2] == 2) 
              || (_nums[0] == 0 && _nums[1] == 2 && _nums[2] == 3));
        Bet memory bet = Bet(8, _size, _nums);
        _placeInsideBet(bet);
    }

    function betFirstFour(uint _size)
        external
    {
        uint8[] memory nums = new uint8[](4);
        for (uint8 i = 0; i < 4;) {
            nums[i] = i;
            unchecked {
                ++i;
            }
        }
        Bet memory bet = Bet(8, _size, nums);
        _placeInsideBet(bet);
    }

    function _placeInsideBet(Bet memory _bet) private {
         // haven't bet yet
        require(bets[msg.sender][currentRound].size == 0);
        bool ok = cashDesk.transferFrom(msg.sender, casinoContract, _bet.size);
        require(ok);
        bets[msg.sender][currentRound] = _bet;
    }


    // OUTSIDE BETS 18 NUMS
    function betLow(uint _size)
        external
    {
        _placeOutsideBet18([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18], _size);
    }

    function betHigh(uint _size) external {
        _placeOutsideBet18([19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36], _size);
    }

    function betRed(uint _size) external {
         _placeOutsideBet18([1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36], _size);
    }

    function betBlack(uint _size) external {
         _placeOutsideBet18([2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35], _size);
    }

    function betOdd(uint _size) external {
        _placeOutsideBet18([1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35], _size);
    } 

    function _placeOutsideBet18(uint8[18] memory _nums, uint _size) private {
         // haven't bet yet
        require(bets[msg.sender][currentRound].size == 0);
        bool ok = cashDesk.transferFrom(msg.sender, casinoContract, _size);
        require(ok);
        uint8[] memory nums = new uint8[](18);
        for (uint i = 0; i < 18;) {
            nums[i] = _nums[i];
            unchecked {
                ++i;
            }
        }
        bets[msg.sender][currentRound] = Bet(1, _size, nums);
    }

    // OUTSIDE BETS 12 NUMS
    // dosens
    function bet1stDozen(uint _size) external {
        _placeOutsideBet12([1,2,3,4,5,6,7,8,9,10,11,12], _size);
    }

    function bet2stDozen(uint _size) external {
        _placeOutsideBet12([13,14,15,16,17,18,19,20,21,22,23,24], _size);
    }

    function bet3stDozen(uint _size) external {
        _placeOutsideBet12([25,26,27,28,29,30,31,32,33,34,35,36], _size);
    }

    // columns
    function bet1stColumn(uint _size) external {
        _placeOutsideBet12([1,4,7,10,13,16,19,22,25,28,31,34], _size);
    }

    function bet2stColumn(uint _size) external {
        _placeOutsideBet12([2,5,8,11,14,17,20,23,26,29,32,35], _size);
    }

    function bet3stColumn(uint _size) external {
        _placeOutsideBet12([3,6,9,12,15,18,21,24,27,30,33,36], _size);
    }

    function betRedSnake(uint _size) external {
        _placeOutsideBet12([1,5,9,12,14,16,19,23,27,30,32,34], _size);
    }

    function _placeOutsideBet12(uint8[12] memory _nums, uint _size) private {
         // haven't bet yet
        require(bets[msg.sender][currentRound].size == 0);
        bool ok = cashDesk.transferFrom(msg.sender, casinoContract, _size);
        require(ok);
        uint8[] memory nums = new uint8[](12);
        for (uint i = 0; i < 12;) {
            nums[i] = _nums[i];
            unchecked {
                ++i;
            }
        }
        bets[msg.sender][currentRound] = Bet(2, _size, nums);
    }
}