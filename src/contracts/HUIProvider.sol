// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import "./HUIToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HUIProvider is Ownable {

    HUIToken public hui;
    address[] public underlyingTokens;

    constructor(address token) Ownable(msg.sender) {
        hui = HUIToken(token);
    }

    function expandUnderlyingTokens(address newUnderlyingToken) public onlyOwner {
        for (uint256 i = 0; i < underlyingTokens.length; i++)
            require(underlyingTokens[i] != newUnderlyingToken, "Token already exists");
        underlyingTokens.push(newUnderlyingToken);
    }

    function deposit(address underlyingToken, uint256 amount) public {
        /// check if the token is supported
        bool isSupported = false;
        for (uint256 i = 0; i < underlyingTokens.length; i++)
            if (underlyingTokens[i] == underlyingToken) {
                isSupported = true;
                break;
            }
        require(isSupported, "Token not supported");
        hui.mintTo(msg.sender, amount);
        ERC20(underlyingToken).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address underlyingToken, uint256 amount) public {
        /// check if the token is supported
        bool isSupported = false;
        for (uint256 i = 0; i < underlyingTokens.length; i++)
            if (underlyingTokens[i] == underlyingToken) {
                isSupported = true;
                break;
            }
        require(isSupported, "Token not supported");
        hui.burnFrom(msg.sender, amount);
        ERC20(underlyingToken).transfer(msg.sender, amount);
    }
}
