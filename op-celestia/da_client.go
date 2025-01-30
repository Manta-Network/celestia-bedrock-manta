package celestia

import (
	"context"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/rollkit/go-da"
	"github.com/rollkit/go-da/proxy"
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
