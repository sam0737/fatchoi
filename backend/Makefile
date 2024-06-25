.PHONY: all
all: ../scripts/bin/bucket_v1

../scripts/bin/bucket_v1: bucket_v1.go
	CGO_ENABLED=0 go build -o $@ $^