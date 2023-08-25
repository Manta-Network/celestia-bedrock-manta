package rollup

import (
	"context"
	"encoding/hex"

	"github.com/aws/aws-sdk-go-v2/service/s3"
	openrpc "github.com/rollkit/celestia-openrpc"
	"github.com/rollkit/celestia-openrpc/types/share"
)

type DAConfig struct {
	Rpc       string
	Namespace share.Namespace
	Client    *openrpc.Client
	AuthToken string
	S3Client  *s3.Client
	S3Bucket  string
}

func NewDAConfig(rpc, token, ns, bucket, region string) (*DAConfig, error) {
	if len(rpc) == 0 {
		return &DAConfig{}, nil
	}

	nsBytes, err := hex.DecodeString(ns)
	if err != nil {
		return nil, err
	}

	namespace, err := share.NewBlobNamespaceV0(nsBytes)
	if err != nil {
		return nil, err
	}

	client, err := openrpc.NewClient(context.Background(), rpc, token)
	if err != nil {
		return nil, err
	}

	return &DAConfig{
		Namespace: namespace,
		Rpc:       rpc,
		Client:    client,

		S3Client: s3.New(s3.Options{Region: region}),
		S3Bucket: bucket,
	}, nil
}
