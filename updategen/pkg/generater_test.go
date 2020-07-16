package pkg

import (
	"testing"

	"github.com/prometheus/common/log"
)

var (
	new = []byte(`test-adaptor:
  image:
    tag: v0.0.1`)
)

func TestGenerater(t *testing.T) {
	if err := GenerateFromYaml("v0.0.3"); err != nil {
		log.Fatal(err)
	}
}
