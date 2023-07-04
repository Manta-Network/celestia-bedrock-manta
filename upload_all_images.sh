#! /bin/bash

build_tag_push () { docker build -t $1 -f $1/Dockerfile . && docker tag $1 716662532931.dkr.ecr.us-west-2.amazonaws.com/$1:celestia && docker image push 716662532931.dkr.ecr.us-west-2.amazonaws.com/$1:celestia; }

build_tag_push op-batcher
build_tag_push op-node
build_tag_push op-proposer

docker build -t 716662532931.dkr.ecr.us-west-2.amazonaws.com/bedrock-deployer:celestia -f ops-bedrock/Dockerfile.bedrock-deployer . && docker image push 716662532931.dkr.ecr.us-west-2.amazonaws.com/bedrock-deployer:celestia
