#!/usr/bin/env bash
set -e

# This script is for setting up the stash and controller accounts.

# Set variables
CFG_DIR=~/.simapp
BUILD_CMD=./cosmos-sdk/build/simd
VALIDATOR=alice
CHAIN_ID=hackatom6-chain

# Key names in keyring
STASH=stash
CONTROLLER=controller

# Get validator address
validator=$("${BUILD_CMD}" keys show $VALIDATOR --bech val --keyring-backend test --output json)
VALIDATOR_ADDRESS=$(echo "${validator}" | jq -r '.address')

# Create stash account in keyring.
$BUILD_CMD keys add $STASH --keyring-backend test 
STASH_ADDRESS=$($BUILD_CMD keys show $STASH -a --keyring-backend test)

# Create controller account in keyring.
$BUILD_CMD keys add $CONTROLLER --keyring-backend test
CONTROLLER_ADDRESS=$($BUILD_CMD keys show $CONTROLLER -a --keyring-backend test)

# Send a lot of funds to STASH.
$BUILD_CMD tx bank send $VALIDATOR $STASH_ADDRESS 10000000stake --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Send funds to CONTROLLER from $STASH for fee purposes.
$BUILD_CMD tx bank send $STASH $CONTROLLER_ADDRESS 100000stake --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Create an authz authorization from STASH to CONTROLLER to perform MsgDelegate, MsgUnbond and MsgRedelegate.
$BUILD_CMD tx authz grant $CONTROLLER_ADDRESS delegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --allowed-validators $VALIDATOR_ADDRESS -y
$BUILD_CMD tx authz grant $CONTROLLER_ADDRESS unbond --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --allowed-validators $VALIDATOR_ADDRESS -y
$BUILD_CMD tx authz grant $CONTROLLER_ADDRESS redelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --allowed-validators $VALIDATOR_ADDRESS -y

# Query authorization grants granted by STASH
$BUILD_CMD q authz granter-grants $STASH_ADDRESS --chain-id $CHAIN_ID

# Query all the authz grants authorized to CONTROLLER from STASH
$BUILD_CMD q authz grants $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

# Set up a feegrant from STASH to CONTROLLER
$BUILD_CMD tx feegrant grant $STASH $CONTROLLER_ADDRESS --spend-limit 10000stake --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Query the feegrant from STASH to CONTROLLER 
$BUILD_CMD q feegrant grant $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

# Query all the grants for CONTROLLER
$BUILD_CMD q feegrant grants $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

# Delegate liquid coins to validator from STASH
$BUILD_CMD tx staking delegate $VALIDATOR_ADDRESS 10stake --from $STASH --keyring-backend test --chain-id $CHAIN_ID --generate-only> tx.json 

# Query the delegations from the STASH account
$BUILD_CMD q staking delegations $STASH_ADDRESS --chain-id $CHAIN_ID

# Exec the MsgDelegate from CONTROLLER on behalf of STASH key
$BUILD_CMD tx authz exec tx.json --from $CONTROLLER --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Revoke the authz for MsgDelegate
$BUILD_CMD tx authz revoke $CONTROLLER_ADDRESS /cosmos.staking.v1beta1.MsgDelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Query all the authz grants authorized to CONTROLLER from STASH, now we only have Unbond and Redelegate since Delegate is revoked
$BUILD_CMD q authz grants $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

# Revoke the authz for MsgUnbond
$BUILD_CMD tx authz revoke $CONTROLLER_ADDRESS /cosmos.staking.v1beta1.MsgUndelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Revoke the authz for MsgRedelegate
$BUILD_CMD tx authz revoke $CONTROLLER_ADDRESS /cosmos.staking.v1beta1.MsgBeginRedelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y

# Query all the authz grants authorized to CONTROLLER from STASH, which returns null since we revoked all the authorizations
$BUILD_CMD q authz grants $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

# Again try to exec MsgDelegate, it should fail because we revoked the authorization for it
$BUILD_CMD tx staking delegate $VALIDATOR_ADDRESS 10stake --from $STASH --keyring-backend test --chain-id $CHAIN_ID --generate-only> tx.json && $BUILD_CMD tx authz exec tx.json --from $CONTROLLER --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block -y
