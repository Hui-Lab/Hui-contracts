// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import "./HUIToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HUIProvider is Ownable {
    HUIToken public hui;
    ERC20[] public underlyingTokens;

    constructor() Ownable(msg.sender) {}

    function setUpVault(address _hui) public onlyOwner {
        hui = HUIToken(_hui);
    }

    function expandUnderlyingTokens(ERC20 newUnderlyingToken) public onlyOwner {
        for (uint256 i = 0; i < underlyingTokens.length; i++)
            require(underlyingTokens[i] != newUnderlyingToken, "Token already exists");
        underlyingTokens.push(newUnderlyingToken);
    }
    
    function deposit(address underlyingToken, uint256 amount) public {
        hui.mintTo(msg.sender, amount);
        ERC20(underlyingToken).transferFrom(msg.sender, address(this), amount);  
    }

    function withdraw(address underlyingToken, uint256 amount) public {
        hui.burnFrom(msg.sender, amount);
        ERC20(underlyingToken).transfer(msg.sender, amount);
    }
}