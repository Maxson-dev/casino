// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";


/**
WARN:
This contract created just for emulation oracle in local blockchain
DO NOT USE IT IN PRODUCTION
*/
contract VRFCoordinatorV2Interface is Ownable {

    event RequestCreated(uint256 indexed requestId, uint32 indexed numWords);

    struct Subscriber {
        VRFConsumerBaseV2 instance;
        bool exist;
    }
    
    mapping (uint => Subscriber) private reqToSub;

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns(uint256) {
        require(msg.sender.code.length > 0, "Contracts only!"); // contracts only
        console.log(msg.sender);
        uint256 reqId = uint(keccak256(abi.encodePacked(keyHash, subId, minimumRequestConfirmations, callbackGasLimit, numWords, block.timestamp, msg.sender)));
        console.log(reqId);

        reqToSub[reqId].exist = true;
        reqToSub[reqId].instance = VRFConsumerBaseV2(msg.sender);

        emit RequestCreated(reqId, numWords);

        return reqId;
    }

    function sendResponse(uint256 _reqId, uint256[] memory _randomWords) 
    external onlyOwner {

        console.log(_reqId);
        console.log(_randomWords[0]);
        
        require(reqToSub[_reqId].exist, "Request is not exist!");
        reqToSub[_reqId].instance.rawFulfillRandomWords(_reqId, _randomWords);
    }
}
