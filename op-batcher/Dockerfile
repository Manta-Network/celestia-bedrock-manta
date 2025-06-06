FROM --platform=$BUILDPLATFORM golang:1.19.9-alpine3.16 as builder

ARG VERSION=v0.0.0

RUN apk add --no-cache make gcc musl-dev linux-headers git jq bash

# build op-batcher with the shared go.mod & go.sum files
COPY ./op-batcher /app/op-batcher
COPY ./op-celestia /app/op-celestia
COPY ./op-bindings /app/op-bindings
COPY ./op-geth /app/op-geth
COPY ./op-node /app/op-node
COPY ./op-service /app/op-service
COPY ./op-signer /app/op-signer
COPY ./go-ethereum-kms-signer /app/go-ethereum-kms-signer
COPY ./go.mod /app/go.mod
COPY ./go.sum /app/go.sum

WORKDIR /app/op-batcher

RUN go mod download

ARG TARGETOS TARGETARCH

RUN make op-batcher VERSION="$VERSION" GOOS=$TARGETOS GOARCH=$TARGETARCH

FROM alpine:3.16

COPY --from=builder /app/op-batcher/bin/op-batcher /usr/local/bin

ENTRYPOINT ["op-batcher"]
