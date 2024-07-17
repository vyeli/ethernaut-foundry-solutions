// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {MagicNum} from "../src/MagicNumber.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/MagicNumber.s.sol --tc MagicNumberSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract MagicNumberSolution is Script {

    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = (vm.envAddress("MAGICNUMBER_INSTANCE"));

    /*
    Attack idea:
    The setSolver function is a public function that sets the solver address
    we can call this function with the address of a contract with runtime opcode <= 10 opcodes (extcodesize <=10) that we are going to deploy previously
    We are going to do this with OPCODE:
    We can use this site https://www.evm.codes/playground to get the correct bytecode base on the opcodes
    [Creation code][Runtime code]

    Runtime code: (load 42 into memory and return it) 602a60005260206000f3
    PUSH1 0x2a - Push 42 to the stack
    PUSH1 0    - Push 0 to the stack (memory location offset in the memory in bytes.)
    MSTORE     - Store 42 in memory mstore(p, v) - store v at memory p to p + 32
    PUSH1 0x20 - Push 32 to the stack
    PUSH1 0    - Push 0 to the stack (memory location offset in the memory in bytes.)
    RETURN     - Return 32 bytes of memory at position 0 return(p, s) - end execution and return data from memory p to p + s, it returns 32 bytes because uint256 is 32 bytes long

    Creation code: Return the runtime code  69602a60005260206000f3600052600a6016f3
    // store the runtime code in memory
    PUSH10 0x602a60005260206000f3 - Push the runtime code to the stack (10 bytes)
    PUSH1 0 - Push 0 to the stack (memory location offset in the memory in bytes.)
    MSTORE  - Store the runtime code in memory mstore(p, v) - store v at memory p to p + 32
    // return 10 bytes from memory starting at offset 22
    PUSH1 0x0a - Push 10 to the stack
    PUSH1 0x16 - Push 22 to the stack because this is the offset of the runtime code in memory (32bytes we just want the last 10 bytes representing the runtime code)
    RETURN 
    */


    function run() external {
            
        vm.startBroadcast(deployerPrivateKey);
        // create the attack contract with assembly
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";
        address solver;

        // deploy the contract with CREATE2 and get the address
        assembly {  // create2(value (ETH sent), offset, size, salt), offset of 32 bytes because the first 32 bytes are the length of the bytecode variable
            solver := create2(0, add(bytecode, 0x20), mload(bytecode), 0)
        }

        // call the setSolver function with the address of the deployer
        (bool sucess, ) = instance.call(abi.encodeWithSignature("setSolver(address)", solver));
        require(sucess, "Failed to call setSolver function");
        MagicNum magicNumberInstance = MagicNum(instance);
        vm.stopBroadcast();

    }

}