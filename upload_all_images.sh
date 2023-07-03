#! /bin/bash

MOD=op-batcher && docker build -t 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia -f $MOD/Dockerfile . && docker image push 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia

MOD=op-proposer && docker build -t 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia -f $MOD/Dockerfile . && docker image push 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia

MOD=op-node && docker build -t 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia -f $MOD/Dockerfile . && docker image push 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia

MOD=bedrock-deployer && docker build -t 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia -f ops-bedrock/bedrock-deployer.Dockerfile . && docker image push 716662532931.dkr.ecr.us-west-2.amazonaws.com/$MOD:celestia
