#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly IMAGE_NAME="${1}"

docker build \
  --file "${MY_DIR}/Dockerfile.augment" \
  --tag "${IMAGE_NAME}" \
  "${MY_DIR}"
