#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker build \
  --file "${MY_DIR}/Dockerfile.augment" \
  --tag cyberdojo/augment_dockerfile \
  "${MY_DIR}" > /dev/null
