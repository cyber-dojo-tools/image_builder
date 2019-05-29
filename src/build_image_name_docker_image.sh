#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker build \
  --file "${MY_DIR}/Dockerfile.image_name" \
  --tag cyberdojo/augment_dockerfile \
  "${MY_DIR}" > /dev/null
