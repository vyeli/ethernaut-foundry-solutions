# OpenZeppelin Ethernaut CTF Solutions using Foundry
This repo solves all Ethernaut CTFs using Foundry framework. Solution are provided as foundry scripts.
You can setup the environment and run the scripts to solve the challenges on Sepolia testnet.

## Getting Started

- All Ethernaut CTFs smart contracts in `/src` folder.
- Solutions are  in `/script` folder.
- The CTF solution file has the same name as CTF contract file name adding `.s` to it.
- If the CTF challenge is `src/Fallback.sol`, the solution will be `script/Fallback.s.sol`.
- Copy the instance address to the .env file to allow the script files to interact with the on-chain challenges.

## Instalation

Update the `foundry` to the latest version.

```bash
foundryup
```

## Setup environment to run the scripts as the .env file

There is a example file `.env.example` in the root folder. Copy it to `.env` and update the values.

```
SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=
MY_ADDRESS=

FALLBACK_INSTANCE=
...
```
| In case using metamask wallet, remember to add the '0x' prefix to the private key.


Change the instance address for each CTF challenge the ethernaut contract generated for you.
For example, if the CTF challenge is `Fallback`, the instance address should be put in the `FALLBACK_INSTANCE` environment variable.


## Run the script

To test the script solution without making real transactions on the blockchain use:

```bash
    forge script script/Fallback.s.sol  --rpc-url $SEPOLIA_RPC_URL -vvvv
```
This will run the script and show the transactions that would be made on the blockchain as a form of simulation.


To run the script solution on the blockchain use:

```bash
    forge script script/Fallback.s.sol  --rpc-url $SEPOLIA_RPC_URL -vvvv --broadcast
```
This will be stored in the blockchain and the transactions will be made on the blockchain.

If there is a extra contract made to crack a challenge you can also add the --verify flag to verify your contract on-chain

### Feel free to make issues!
