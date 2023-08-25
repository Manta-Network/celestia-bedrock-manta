package celestia

import (
	"encoding"
	"encoding/binary"
	"errors"
)

var (
	ErrInvalidSize    = errors.New("invalid size")
	ErrInvalidVersion = errors.New("invalid version")
)

const CurrentVersion = 2

// Framer defines a way to encode/decode a FrameRef.
type Framer interface {
	encoding.BinaryMarshaler
	encoding.BinaryUnmarshaler
}

// FrameRef contains the reference to the specific frame on celestia and
// satisfies the Framer interface.
// Instead of storing the block hash, require the Celestia block timestamp
// to be less than the l1 block timestamp for the transaction to be valid.
// Also require the Celestia block to be posted at most 24 hours before
// the corresponding l1 block.
// If these conditions are not met, the l1 block should be declared invalid.
type FrameRef struct {
	Version      uint8
	BlockHeight  uint64
	TxCommitment []byte
}

var _ Framer = &FrameRef{}

// MarshalBinary encodes the FrameRef to binary
// serialization format: version + height + commitment
//
//	----------------------------------------
//
// | 1 byte uint8    | 8 byte uint64  |  32 byte commitment |
//
//	----------------------------------------
//
// | <-- version --> | <-- height --> | <-- commitment -->  |
//
//	----------------------------------------
//
// Note that version should not be 0x78 to avoid conflicts
// with the zlib compression header.
func (f *FrameRef) MarshalBinary() ([]byte, error) {
	ref := make([]byte, 9+len(f.TxCommitment))

	ref[0] = CurrentVersion
	binary.LittleEndian.PutUint64(ref[1:9], f.BlockHeight)
	copy(ref[9:], f.TxCommitment)

	return ref, nil
}

// UnmarshalBinary decodes the binary to FrameRef
// serialization format: version + height + commitment
//
//	----------------------------------------
//
// | 1 byte uint8    | 8 byte uint64  |  32 byte commitment |
//
//	----------------------------------------
//
// | <-- version --> | <-- height --> | <-- commitment -->  |
//
//	----------------------------------------
func (f *FrameRef) UnmarshalBinary(ref []byte) error {
	if len(ref) <= 9 {
		return ErrInvalidSize
	}
	f.Version = ref[0]
	if f.Version != CurrentVersion {
		return ErrInvalidVersion
	}
	f.BlockHeight = binary.LittleEndian.Uint64(ref[1:9])
	f.TxCommitment = ref[9:]
	return nil
}
