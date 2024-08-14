// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {DoubleEntryPoint, Forta, CryptoVault, LegacyToken, IDetectionBot} from "../src/DoubleEntryPoint.sol";

// $ source .env      # This is to store the environmental variables in the shell session
// $ forge script script/DoubleEntryPoint.s.sol --tc DoubleEntryPointSolution --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

contract DoubleEntryPointSolution is Script {
    // get the environmental variables
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    // this is the instance address created by the ethernaut contract
    address public instance = vm.envAddress("DOUBLEENTRYPOINT_INSTANCE");

    /* The DoubleEntryPoint is the upgraded version of the LegacyToken contract, the legacyToken delegate the transfer function to the DoubleEntryPoint contract
       meaning that each transfer is instead performed by the DoubleEntryPoint token, effectively moving only DoubleEntryPoint tokens.
       This means that when we call the sweepToken(legacyToken) function, the DoubleEntryPoint token will be transferred to the sweptTokensRecipient address effectively draining the contract.
       This is the vulnerability of the contract.

       We need to create a IDetectionBot that has a handleTransaction function that will be called in the notify modifier when the delegateTransfer function is called in the DoubleEntryPoint token.
       we receive the msg.data in the handleTransaction function and we can decode the msg.data to get the from address and raise an alert if the from address is the vault address.
       This will prevent the DoubleEntryPoint token from being move out of the vault.

    */

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        // get the instance of DoubleEntryPoint
        DoubleEntryPoint doubleEntryPoint = DoubleEntryPoint(instance);

        // get the instance of the CryptoVault
        address cryptoVault = doubleEntryPoint.cryptoVault();
        console.log("CryptoVault address: ", address(cryptoVault));

        CryptoVault cryptoVaultInstance = CryptoVault(cryptoVault);
        // get the current underlying token
        address underlyingToken = address(cryptoVaultInstance.underlying());
        console.log("Underlying token address: ", underlyingToken);
        // get the Forta instance
        Forta fortaInstance = doubleEntryPoint.forta();
        // register the detection bot
        myDetectionBot detectionBot = new myDetectionBot(address(fortaInstance), address(cryptoVault));
        fortaInstance.setDetectionBot(address(detectionBot));
        

        vm.stopBroadcast();
    }


}

contract myDetectionBot is IDetectionBot {

    Forta immutable fortaInstance;
    address immutable cryptoVaultInstance;

    constructor(address fortaAddress, address cryptoVaultAddress) {
        fortaInstance = Forta(fortaAddress);
        cryptoVaultInstance = cryptoVaultAddress;
    }

    function handleTransaction(address user, bytes calldata msgData) external override {

        // check the msgData to see if the delegateTransfer function is called by the cryptoVaultInstance
        // delegateTransfer(address to, uint256 value, address origSender)
        // we will decode the msgData to get the from address, starting from the 4th index because the first 4 bytes is the function signature
        (,, address from) = abi.decode(msgData[4:], (address, uint256, address));
        // if the from address is the cryptoVaultInstance, we raise an alert because the DoubleEntryPoint token is being moved out of the vault
        if (from == cryptoVaultInstance) {
            fortaInstance.raiseAlert(user);
        }
    }

}