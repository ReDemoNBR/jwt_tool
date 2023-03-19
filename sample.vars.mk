# REQUIRED VARIABLES
BUILDER ?= podman
BUILD_PLATFORM ?= linux/amd64,linux/arm64/v8
BUILD_CONTEXT ?= ./
LOCAL_IMAGE_NAME ?= local:temp
TAG_SUFFIX ?= bullseye
REMOTE_IMAGE_REPO ?= localhost:5000/rdnxk/jwt_tool/test
REMOTE_IMAGE_NAME ?= $(REMOTE_IMAGE_REPO):$(TAG_SUFFIX)
COSIGN_PRIVATE_KEY ?= cosign.key
COSIGN_PUBLIC_KEY ?= cosign.pub
COSIGN_PASSWORD ?= foobar

# OPTIONAL VARIABLES
BUILD_OPTS ?= --squash --jobs 2
PUSH_OPTS ?= --tls-verify=false
