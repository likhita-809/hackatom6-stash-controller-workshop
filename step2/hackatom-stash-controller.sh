#!/usr/bin/env bash
set -e

# This script is for setting up the stash and controller accounts, and sending
# some txs from controller on behalf of stash. All commands are commented.

# Set variables
CFG_DIR=~/.simapp
BUILD_CMD=../step1/cosmos-sdk/build/simd
VALIDATOR=alice
CHAIN_ID=hackatom6-chain
MIN_FEES=20stake

# Key names in keyring
STASH=stash
CONTROLLER=controller

# Get validator address
VALIDATOR_ADDRESS=$($BUILD_CMD keys show $VALIDATOR --bech val -a --keyring-backend test)

echo
echo "Create stash account in keyring."
$BUILD_CMD keys add $STASH --keyring-backend test 
STASH_ADDRESS=$($BUILD_CMD keys show $STASH -a --keyring-backend test)

echo
echo "Create controller account in keyring."
$BUILD_CMD keys add $CONTROLLER --keyring-backend test
CONTROLLER_ADDRESS=$($BUILD_CMD keys show $CONTROLLER -a --keyring-backend test)

echo
echo "Send a lot of funds to STASH."
$BUILD_CMD tx bank send $VALIDATOR $STASH_ADDRESS 10000000stake --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y

echo
echo "Create 3 authz authorizations from STASH to CONTROLLER."
echo "Create an authz authorization to perform MsgDelegate."
$BUILD_CMD tx authz grant $CONTROLLER_ADDRESS delegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y --allowed-validators $VALIDATOR_ADDRESS

echo
echo "Create an authz authorization to perform MsgUndelegate."
$BUILD_CMD tx authz grant $CONTROLLER_ADDRESS unbond --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y --allowed-validators $VALIDATOR_ADDRESS

echo
echo "Create an authz authorization to perform MsgRedelegate."
$BUILD_CMD tx authz grant $CONTROLLER_ADDRESS redelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y --allowed-validators $VALIDATOR_ADDRESS

echo
echo "Query authorization grants granted by STASH"
$BUILD_CMD q authz granter-grants $STASH_ADDRESS --chain-id $CHAIN_ID

echo
echo "Query all the authz grants authorized to CONTROLLER from STASH"
$BUILD_CMD q authz grants $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

echo
echo "Set up a feegrant of 200stake from STASH to CONTROLLER to pay tx fees"
$BUILD_CMD tx feegrant grant $STASH $CONTROLLER_ADDRESS --spend-limit 200stake --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y

echo
echo "Query the feegrant from STASH to CONTROLLER"
$BUILD_CMD q feegrant grant $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

echo
echo "Query all the grants for CONTROLLER"
$BUILD_CMD q feegrant grants $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

echo
echo "Delegate liquid coins (42stake) to validator from STASH (no signature from STASH needed!)"
$BUILD_CMD tx staking delegate $VALIDATOR_ADDRESS 42stake --from $STASH --keyring-backend test --chain-id $CHAIN_ID --generate-only> tx.json 

echo
echo "Exec the MsgDelegate from CONTROLLER on behalf of STASH key (STASH pays for fees!)"
$BUILD_CMD tx authz exec tx.json --from $CONTROLLER --fee-account $STASH_ADDRESS --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y

echo
echo "Query again the feegrant from STASH to CONTROLLER (it's less than the initial 200stake)"
$BUILD_CMD q feegrant grant $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

echo
echo "Query the delegations from the STASH account"
$BUILD_CMD q staking delegations $STASH_ADDRESS --chain-id $CHAIN_ID

echo
echo "Revoke the authz for MsgDelegate"
$BUILD_CMD tx authz revoke $CONTROLLER_ADDRESS /cosmos.staking.v1beta1.MsgDelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y

echo
echo "Query all the authz grants authorized to CONTROLLER from STASH, now we only have Unbond and Redelegate since Delegate is revoked"
$BUILD_CMD q authz grants $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

echo
echo "Revoke the authz for MsgUndelegate"
$BUILD_CMD tx authz revoke $CONTROLLER_ADDRESS /cosmos.staking.v1beta1.MsgUndelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y

echo
echo "Revoke the authz for MsgRedelegate"
$BUILD_CMD tx authz revoke $CONTROLLER_ADDRESS /cosmos.staking.v1beta1.MsgBeginRedelegate --from $STASH --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y

echo
echo "Query all the authz grants authorized to CONTROLLER from STASH, which returns null since we revoked all the authorizations"
$BUILD_CMD q authz grants $STASH_ADDRESS $CONTROLLER_ADDRESS --chain-id $CHAIN_ID

echo
echo "Again try to exec MsgDelegate, it should fail because we revoked the authorization for it"
$BUILD_CMD tx staking delegate $VALIDATOR_ADDRESS 42stake --from $STASH --keyring-backend test --chain-id $CHAIN_ID --generate-only> tx.json && $BUILD_CMD tx authz exec tx.json --from $CONTROLLER --keyring-backend test --chain-id $CHAIN_ID --broadcast-mode block --fees $MIN_FEES -y
