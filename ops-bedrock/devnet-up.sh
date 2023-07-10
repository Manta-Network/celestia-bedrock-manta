#!/usr/bin/env bash

# This script starts a local devnet using Docker Compose. We have to use
# this more complicated Bash script rather than Compose's native orchestration
# tooling because we need to start each service in a specific order, and specify
# their configuration along the way. The order is:
#
# 1. Start L1.
# 2. Compile contracts.
# 3. Deploy the contracts to L1 if necessary.
# 4. Start L2, inserting the compiled contract artifacts into the genesis.
# 5. Get the genesis hashes and timestamps from L1/L2.
# 6. Generate the rollup driver's config using the genesis hashes and the
#    timestamps recovered in step 4 as well as the address of the OptimismPortal
#    contract deployed in step 3.
# 7. Start the rollup driver.
# 8. Start the L2 output submitter.
#
# The timestamps are critically important here, since the rollup driver will fill in
# empty blocks if the tip of L1 lags behind the current timestamp. This can lead to
# a perceived infinite loop. To get around this, we set the timestamp to the current
# time in this script.
#
# This script is safe to run multiple times. It stores state in `.devnet`, and
# contracts-bedrock/deployments/devnetL1.
#
# Don't run this script directly. Run it using the makefile, e.g. `make devnet-up`.
# To clean up your devnet, run `make devnet-clean`.

set -eu

L1_URL="http://localhost:8545"
L2_URL="http://localhost:9545"

OP_NODE="$PWD/op-node"
CONTRACTS_BEDROCK="$PWD/packages/contracts-bedrock"
NETWORK=devnetL1
DEVNET="$PWD/.devnet"

# Helper method that waits for a given URL to be up. Can't use
# cURL's built-in retry logic because connection reset errors
# are ignored unless you're using a very recent version of cURL
function wait_up {
  echo -n "Waiting for $1 to come up..."
  i=0
  until curl -s -f -o /dev/null "$1"
  do
    echo -n .
    sleep 0.25

    ((i=i+1))
    if [ "$i" -eq 300 ]; then
      echo " Timeout!" >&2
      exit 1
    fi
  done
  echo "Done!"
}

mkdir -p ./.devnet

# If KMS_TEST is set use KMS keys for devnet proposer and batcher
# Must provide env variables AWS_SECRET_ID and AWS_SECRET_KEY that
# have access to the KMS keys (test-op-batcher and test-op-proposer in us-west-2)
# in the sandbox account to test
if [ -n "${KMS_TEST:-}" ]; then
  echo "KMS test is set, using KMS keys for devnet proposer and batcher"
  export OP_BATCHER_KMS_ID='e7a73e3f-7f23-40f4-8349-581a75e5f306'
  export OP_BATCHER_ADDRESS='0x2e7c9f1dc98ff98df72027991ee41ea3f2f6c472'
  export OP_PROPOSER_KMS_ID='mrk-47bd8e486edd48acbbc64c59f4352fd2'
  export OP_PROPOSER_ADDRESS='0x68fa66122a3c1609b0ef4b3a625dd8795be29479'
  export KMS_REGION='us-west-2'
else
  echo "KMS test is not set, using mnemonics for devnet proposer and batcher"
  export OP_BATCHER_MNEMONIC='test test test test test test test test test test test junk'
  export OP_PROPOSER_MNEMONIC='test test test test test test test test test test test junk'
  export OP_BATCHER_SEQUENCER_HD_PATH="m/44'/60'/0'/0/2"
  export OP_PROPOSER_L2_OUTPUT_HD_PATH="m/44'/60'/0'/0/1"
  export OP_PROPOSER_ADDRESS='0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
  export OP_BATCHER_ADDRESS='0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'
fi

# Regenerate the L1 genesis file if necessary. The existence of the genesis
# file is used to determine if we need to recreate the devnet's state folder.
if [ ! -f "$DEVNET/done" ]; then
  echo "Regenerating genesis files"

  TIMESTAMP=$(date +%s | xargs printf '0x%x')
  cat "$CONTRACTS_BEDROCK/deploy-config/devnetL1.json" \
  | jq -r ".l1GenesisBlockTimestamp = \"$TIMESTAMP\"" \
  | jq -r ".batchSenderAddress = \"$OP_BATCHER_ADDRESS\"" \
  | jq -r ".l2OutputOracleProposer = \"$OP_PROPOSER_ADDRESS\"" \
  > /tmp/bedrock-devnet-deploy-config.json

  (
    cd "$OP_NODE"
    go run cmd/main.go genesis devnet \
        --deploy-config /tmp/bedrock-devnet-deploy-config.json \
        --outfile.l1 $DEVNET/genesis-l1.json \
        --outfile.l2 $DEVNET/genesis-l2.json \
        --outfile.rollup $DEVNET/rollup.json
    touch "$DEVNET/done"
  )
fi

# Bring up L1.
(
  cd ops-bedrock
  echo "Bringing up L1..."
  DOCKER_BUILDKIT=1 docker-compose -f docker-compose-devnet.yml build --progress plain
  docker-compose -f docker-compose-devnet.yml up -d l1
  wait_up $L1_URL
)
if [ -n "${KMS_TEST:-}" ]; then
  cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 $OP_PROPOSER_ADDRESS
  cast send --value 10ether --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 $OP_BATCHER_ADDRESS
fi

# Bring up L2.
(
  cd ops-bedrock
  echo "Bringing up L2..."
  docker-compose -f docker-compose-devnet.yml up -d l2
  wait_up $L2_URL
)

L2OO_ADDRESS="0x6900000000000000000000000000000000000000"

# Bring up everything else.
(
  cd ops-bedrock
  echo "Bringing up devnet..."
  L2OO_ADDRESS="$L2OO_ADDRESS" \
      docker-compose -f docker-compose-devnet.yml up -d op-proposer op-batcher

  echo "Bringing up stateviz webserver..."
  docker-compose -f docker-compose-devnet.yml up -d stateviz
)

echo "Devnet ready."
