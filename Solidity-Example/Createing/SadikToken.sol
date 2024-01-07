// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20{
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }
}

contract SToekn is ERC20{
    address public owner;
    constructor()ERC20("Sadik Toekn","ST")
    {
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
        owner=msg.sender;
    }

    modifier onlyOwner(){ //sahıp olup olmadıgının kontrolu yapılıcak
        require(msg.sender==owner,"Not owner");
        _;
    }

    function Mint(uint256 amount)public onlyOwner{ //Sadece owner para uretımı yapa bılıcek 
        _mint(msg.sender, 100 * 10 ** uint(decimals()));
    }
}


