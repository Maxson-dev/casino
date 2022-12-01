// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils.sol";
import "./consumer.sol";
import "./chip.sol";
import "./roulette.sol";
import "hardhat/console.sol";


contract Casino is Ownable, VRFv2Consumer, Roulette {

    enum Game { Roulette, SlotMachine }

    event RequestFillfulled(uint256 indexed requestId, uint256[] indexed randomNums);

    struct Request {
        bool exist;
        bool filfulled;
        Game src;
        uint[] nums;
    }

    mapping (uint => Request) public requests;

    uint public chipPrice;
    address chipAddr;

    constructor(ConsumerConfig memory _consumerConfig, RouletteConfig memory _rouletteConfig) 
        VRFv2Consumer(_consumerConfig)
        Roulette(_rouletteConfig)
    {

    }
    
    function setChipPrice(uint _price) 
        external 
        onlyOwner 
    {
        chipPrice = _price;
    }

    function spinWheel() 
        external 
        onlyCroupier 
    {
        require(startBettingTime + timeForBets < block.timestamp);
        roundStarted = true;
        emit NoMoreBets(currentRound);
        uint reqId = requestRandomness(1);
        requests[reqId].exist = true; 
        requests[reqId].src = Game.Roulette;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) 
        internal
        override 
    {
        require(requests[_requestId].exist);
        requests[_requestId].filfulled = true;
        requests[_requestId].nums = _randomWords;
        emit RequestFillfulled(_requestId, _randomWords);

        if (requests[_requestId].src == Game.Roulette) {
            uint winNum = _randomWords[0];
            roundStarted = false;
            emit RoundEnded(currentRound, winNum);
            winNums[currentRound] = winNum;
            startBettingTime = block.timestamp;
            currentRound++;
        }
    }



}

