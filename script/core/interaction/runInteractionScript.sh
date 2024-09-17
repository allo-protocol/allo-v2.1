#!/bin/bash

# Function to dynamically map chains to variables
# Relevant issue that would deprecate this script if solved: https://github.com/foundry-rs/foundry/issues/7726
deploy() {
  chain=$1
  scriptName=$2
  case "$chain" in
    "sepolia")
      RPC_URL="$SEPOLIA_RPC_URL"
      ;;
    "mainnet")
      RPC_URL="$MAINNET_RPC_URL"
      ;;
    "fuji")
      RPC_URL="$FUJI_RPC_URL"
      ;;
    "celo-testnet")
      RPC_URL="$CELO_TESTNET_RPC_URL"
      ;;
    "celo-mainnet")
      RPC_URL="$CELO_RPC_URL"
      ;;
    "arbitrum-mainnet")
      RPC_URL="$ARBITRUM_RPC_URL"
      ;;
    "optimism-sepolia")
      RPC_URL="$OPTIMISM_SEPOLIA_RPC_URL"
      ;;
    "optimism-mainnet")
      RPC_URL="$OPTIMISM_RPC_URL"
      ;;
    "arbitrum-sepolia")
      RPC_URL="$ARBITRUM_SEPOLIA_RPC_URL"
      ;;
    "base")
      RPC_URL="$BASE_RPC_URL"
      ;;
    "polygon")
      RPC_URL="$POLYGON_RPC_URL"
      ;;
    "avalanche")
      RPC_URL="$AVALANCHE_RPC_URL"
      ;;
    "scroll")
      RPC_URL="$SCROLL_RPC_URL"
      ;;
    "ftmTestnet")
      RPC_URL="$FTM_TESTNET_RPC_URL"
      ;;
    "fantom")
      RPC_URL="$FTM_RPC_URL"
      ;;
    "filecoin-mainnet")
      RPC_URL="$FILECOIN_RPC_URL"
      ;;
    "filecoin-calibration")
      RPC_URL="$FILECOIN_CALIBRATION_RPC_URL"
      ;;
    "sei-devnet")
      RPC_URL="$SEI_DEVNET_RPC_URL"
      ;;
    "sei-mainnet")
      RPC_URL="$SEI_RPC_URL"
      ;;
    "lukso-testnet")
      RPC_URL="$LUKSO_TESTNET_RPC_URL"
      ;;
    "lukso-mainnet")
      RPC_URL="$LUKSO_RPC_URL"
      ;;
    "zkSyncTestnet")
      RPC_URL="$ZK_SYNC_TESTNET_RPC_URL"
      ;;
    "zkSyncMainnet")
      RPC_URL="$ZK_SYNC_RPC_URL"
      ;;
    "local")
      RPC_URL="127.0.0.1:8545"
      ;;
    *)
      echo "Error: Unknown chain '$chain'"
      exit 1
      ;;
  esac

  # Check if required variables are set
  if [ -z "$RPC_URL" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "Error: Missing environment variables."
    exit 1
  fi

  # Deploy script with resolved variables
  if [ "$chain" == "zkSyncMainnet" ] || [ "$chain" == "zkSyncTestnet" ]; then
    forge script "$scriptName" --zksync --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY"
  else
    forge script "$scriptName" --rpc-url "$RPC_URL" --broadcast --private-key "$DEPLOYER_PRIVATE_KEY"
  fi
}

# Ensure the chain argument is provided
if [ -z "$1" ]; then
  echo "<chain> not provided. Usage: script/deployAllo.sh <chain>"
  exit 1
fi

# Ensure the script name argument is provided
if [ -z "$2" ]; then
  echo "<scriptName> not provided. Usage: script/deployAllo.sh <chain>"
  exit 1
fi

# Source the environment variables from the .env file
source .env

# Call the deploy function with the provided chain argument
deploy "$1"
