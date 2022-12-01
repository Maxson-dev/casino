// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chip is ERC20, Ownable {

    address public casinoContract; 

    constructor(address _casinoContract, uint _supply) ERC20("Casino chip", "CHIP") {
        casinoContract = _casinoContract;
        _mint(_casinoContract, _supply);
    }

    function mintForCasino(uint _supply) public onlyOwner {
        _mint(casinoContract, _supply);
    }
}