// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./VFRCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct ConsumerConfig {
      address vrfCoordinator;
      bytes32 keyHash;
      uint64 subId;
      uint32 callbackGasLimit;
      uint16 requestConfirmations;
}

abstract contract VRFv2Consumer is VRFConsumerBaseV2, Ownable  {

    event RequestCreated(uint256 indexed requestId, uint32 numWords);
    
    VRFCoordinatorV2Interface private vrfCoordinatorInstance;

    bytes32 private keyHash;
    uint64 private subId;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;


    constructor(ConsumerConfig memory config) 
        VRFConsumerBaseV2(config.vrfCoordinator) 
    {
        keyHash = config.keyHash;
        subId = config.subId;
        requestConfirmations = config.requestConfirmations;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorInstance = VRFCoordinatorV2Interface(config.vrfCoordinator);
    }

    function requestRandomness(uint32 _numWords) internal returns(uint256) {
        uint256 reqId = vrfCoordinatorInstance.requestRandomWords(
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            _numWords
        );
        emit RequestCreated(reqId, _numWords);
        return reqId;
    }
}