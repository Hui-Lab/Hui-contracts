// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HUIToken is ERC20, AccessControl {
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    constructor() ERC20("HUI Token", "HUI") {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function grantMinterRole(address minter) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(VAULT_ROLE, minter);
    }

    function mintTo(address to, uint256 amount) public {
        require(hasRole(VAULT_ROLE, msg.sender), "Caller is not a vault");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) public {
        require(hasRole(VAULT_ROLE, msg.sender), "Caller is not a vault");
        _burn(from, amount);
    }
}
