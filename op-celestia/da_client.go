package celestia

import (
	"context"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/celestiaorg/go-square/blob"
	"github.com/celestiaorg/go-square/inclusion"
	"github.com/celestiaorg/go-square/namespace"
	"github.com/ethereum/go-ethereum/log"
	"github.com/rollkit/go-da"
	"github.com/rollkit/go-da/proxy"
	"github.com/tendermint/tendermint/crypto/merkle"
)

type DAClient struct {
	Client       da.DA
	GetTimeout   time.Duration
	Namespace    da.Namespace
	FallbackMode string
	GasPrice     float64
	S3Client     *s3.Client
	S3Bucket     string
}

func NewDAClient(rpc, token, namespace, fallbackMode string, gasPrice float64, s3region string, s3bucket string, auth bool) (*DAClient, error) {
	client, err := proxy.NewClient(rpc, token)
	if err != nil {
		return nil, err
	}

	//CALDERA does not tolarate 58 size strings for namespace
	//we have to fix this here
	//and then again adjust in calldata_source downloadS3Data and driver.go uploadS3Data to trim
	log.Warn("Checking namespace for backwards compatibility.", "len", len(namespace))
	if len(namespace) != 58 {
		namespace = "00000000000000000000000000000000000000" + namespace
		log.Warn("Namespace has been adjusted.", "namespace", namespace)
	}

	ns, err := hex.DecodeString(namespace)
	if err != nil {
		return nil, err
	}
	if fallbackMode != "disabled" && fallbackMode != "blobdata" && fallbackMode != "calldata" {
		return nil, fmt.Errorf("celestia: unknown fallback mode: %s", fallbackMode)
	}
	var s3Client *s3.Client
	if auth {
		awscfg, err := config.LoadDefaultConfig(context.Background(),
			config.WithRegion(s3region),
		)
		if err != nil {
			return nil, err
		}
		s3Client = s3.NewFromConfig(awscfg)
	} else {
		s3Client = s3.New(s3.Options{Region: s3region})
	}
	return &DAClient{
		Client:       client,
		GetTimeout:   time.Minute,
		Namespace:    ns,
		FallbackMode: fallbackMode,
		GasPrice:     gasPrice,
		S3Client:     s3Client,
		S3Bucket:     s3bucket,
	}, nil
}

func CreateCommitment(data da.Blob, ns da.Namespace) ([]byte, error) {
	ins, err := namespace.From(ns)
	if err != nil {
		return nil, err
	}
	return inclusion.CreateCommitment(blob.New(ins, data, 0), merkle.HashFromByteSlices, 64)
}
