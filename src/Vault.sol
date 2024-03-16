// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import "./HUIToken.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// interface Vault {
//     function updateStateVault() external {}

//     function 
// }

contract Vault {
    using EnumerableSet for EnumerableSet.AddressSet;

    HUIToken public immutable hui;

    struct User {
        uint256 entryTime;
        uint256 period;
        uint256 amountEachPeriod;
        uint256 totalPay;
        uint256 currentPaymentTime;
        bool expired;
    }
    mapping(address user => User) public userDetails;
    EnumerableSet.AddressSet userEntry;
    
    uint256 public totalFee = 0;
    uint256 public managerClaimable = 0;
    address public manager;

    constructor(address _hui, uint256 _fee) {
        hui = HUIToken(_hui);
        totalFee = _fee;
        manager = msg.sender;
    }

    function getNumberCompleteUserInVault() public view returns (uint256) {
        uint256 Count = 0;
        for (uint256 i = 0; i < userEntry.length(); ++ i) {
            if (userDetails[userEntry.at(i)].totalPay < totalFee) continue;
            ++ Count;
        }
        return Count;
    }

    function managerClaim() public {
        require(msg.sender == manager, "only manager can claim reward");
        hui.transfer(manager, managerClaimable);
    }

    function distribute(address expiredUser) internal {
        if (userEntry.length() == 0) return;
        uint256 value = userDetails[expiredUser].totalPay;
        uint256 numberCompleteUserInVault = getNumberCompleteUserInVault();
        uint256 userClaimable = value / (numberCompleteUserInVault * 2);
        for (uint256 i = 0; i < userEntry.length(); ++ i) {
            if (userDetails[userEntry.at(i)].totalPay < totalFee) continue;
            userDetails[userEntry.at(i)].totalPay += userClaimable;
        }
        uint256 remain = value - userClaimable * numberCompleteUserInVault;
        managerClaimable += remain;
    }

    function updateStateVault(address user) public {
        if (userEntry.contains(user) == false) return;
        if (block.timestamp > getNextPaymentTime() && userDetails[user].totalPay < totalFee) {
            require(userDetails[user].expired == false);
            userDetails[user].expired = true;
        }
        if (userDetails[user].expired == true) {
            distribute(user);
            delete userDetails[user];
            userEntry.remove(user);
        }
    }

    function getReward() public {
        for (uint256 i = 0; i < userEntry.length(); ++ i) {
            updateStateVault(userEntry.at(i));
        }
    }

    function maximumPeriod() public pure returns (uint256) {
        return 365 days;
    }

    function minimumPeriod() public pure returns (uint256) {
        return 1 days;
    }

    function getNextPaymentTime() public view returns (uint256) {
        return userDetails[msg.sender].entryTime + userDetails[msg.sender].currentPaymentTime * userDetails[msg.sender].period;
    }

    function getAmountNeedToPay() public view returns (uint256) {
        return (userDetails[msg.sender].currentPaymentTime + 1) * userDetails[msg.sender].amountEachPeriod;
    }

    function entryHui(uint256 period, uint256 amountEachPeriod) public {
        updateStateVault(msg.sender);
        require(period <= maximumPeriod() && period >= minimumPeriod(), "Period must be between 1 day and 365 days");
        require(period % 1 days == 0, "Period must be a multiple of 1 day");
        require(amountEachPeriod > 0 && amountEachPeriod <= hui.balanceOf(msg.sender), "AmountEachPeriod must be greater than 0 and less than or equal to the balance of the user");
        require(amountEachPeriod * period >= totalFee, "AmountEachPeriod * period must be greater than or equal to totalFee");
        require(userEntry.contains(msg.sender) == false, "User should pay, not entry");
        hui.transferFrom(msg.sender, address(this), amountEachPeriod);
        userDetails[msg.sender].entryTime = block.timestamp;
        userDetails[msg.sender].period = period;
        userDetails[msg.sender].amountEachPeriod = amountEachPeriod;
        userDetails[msg.sender].currentPaymentTime = 1;
        userDetails[msg.sender].totalPay = amountEachPeriod;
        userEntry.add(msg.sender);
    }     

    function pay() public {
        updateStateVault(msg.sender);
        require(userDetails[msg.sender].totalPay < totalFee, "You pay total fee needed");
        require(userEntry.contains(msg.sender) == true, "User should entry, not pay");
        hui.transferFrom(msg.sender, address(this), userDetails[msg.sender].amountEachPeriod);
        userDetails[msg.sender].totalPay += userDetails[msg.sender].amountEachPeriod;
        userDetails[msg.sender].currentPaymentTime ++;
    }

    function withdraw() public {
        updateStateVault(msg.sender);
        require(userDetails[msg.sender].totalPay >= totalFee, "You should pay all fee needed");
        require(userEntry.contains(msg.sender) == true, "User should entry, not withdraw");
        hui.transfer(msg.sender, userDetails[msg.sender].totalPay);
        delete userDetails[msg.sender];
        userEntry.remove(msg.sender);
    }

    function getRewardAndWithdraw() public {
        updateStateVault(msg.sender);
        require(userDetails[msg.sender].totalPay >= totalFee, "You should pay all fee needed");
        require(userEntry.contains(msg.sender) == true, "User should entry, not withdraw");
        getReward();
        hui.transfer(msg.sender, userDetails[msg.sender].totalPay);
        delete userDetails[msg.sender];
        userEntry.remove(msg.sender);
    }
}