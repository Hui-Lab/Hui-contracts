// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HUIToken is ERC20, Ownable {
    address public provider;

    constructor() ERC20("HUI Token", "HUI") Ownable(_msgSender()) {}

    function setProvider(address _provider) public onlyOwner {
        provider = _provider;
    }

    function mintTo(address to, uint256 amount) public {
        require(_msgSender() == provider, "Caller is not the provider");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        require(_msgSender() == provider, "Caller is not the provider");
        _burn(from, amount);
    }
}
