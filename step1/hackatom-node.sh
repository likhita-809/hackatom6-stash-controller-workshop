#!/usr/bin/env bash
set -e

# This script is for running a local node, mostly for testing and demo purposes.
# It creates a chain with one validator, called `ALICE`. The native token of
# this chain is "stake", and `ALICE`, being the only existing account in the
# chain at genesis, has lots of them.

# Clone the SDK repo, we use the latest stable version: v0.44.
if [[ ! -d cosmos-sdk ]]
then
    git clone https://github.com/cosmos/cosmos-sdk --depth 2 --branch master
fi


# Build the SDK's blockchain node binary, called "simapp"
cd cosmos-sdk
make build
cd ..

# Set variables
CFG_DIR=~/.simapp
BUILD_CMD=./cosmos-sdk/build/simd
VALIDATOR=alice
CHAIN_ID=hackatom6-chain

# Cleanup previous installations, if any.
rm -rf $CFG_DIR

# Add ALICE's key to the keyring.
$BUILD_CMD keys add $VALIDATOR --keyring-backend test
VALIDATOR_ADDRESS=$($BUILD_CMD keys show $VALIDATOR -a --keyring-backend test)

# Initialize the genesis file. It is available under $CFG_DIR/config/genesis.json.
$BUILD_CMD init $VALIDATOR --chain-id $CHAIN_ID
$BUILD_CMD add-genesis-account $VALIDATOR_ADDRESS 10000000000stake
$BUILD_CMD gentx $VALIDATOR 1000000000stake --keyring-backend test --chain-id $CHAIN_ID
$BUILD_CMD collect-gentxs

# Run the node.
$BUILD_CMD start --minimum-gas-prices 0.0000001stake

# Leave the node running in a terminal. You can move on to step 2 now.
