#!/usr/bin/env bash
set -e

# This script is for running a simapp node. TODO add more details

# Clone the SDK repo
git clone https://github.com/cosmos/cosmos-sdk
cd cosmos-sdk

# Build the SDK's blockchain node binary, called "simapp"
make build
cd ..

# Set variables
CFG_DIR=~/.simapp
BUILD_CMD=./cosmos-sdk/build/simd
VALIDATOR=alice
CHAIN_ID=hackatom6-chain

rm -rf $CFG_DIR
$BUILD_CMD keys add $VALIDATOR --keyring-backend test
VALIDATOR_ADDRESS=$($BUILD_CMD keys show $VALIDATOR -a --keyring-backend test)
$BUILD_CMD init $VALIDATOR --chain-id $CHAIN_ID
# 30s voting period
sed -i 's/"voting_period": "172800s"/"voting_period": "30s"/' $CFG_DIR/config/genesis.json
$BUILD_CMD add-genesis-account $VALIDATOR_ADDRESS 10000000000stake
$BUILD_CMD gentx $VALIDATOR 1000000000stake --keyring-backend test --chain-id $CHAIN_ID
$BUILD_CMD collect-gentxs

$BUILD_CMD start
