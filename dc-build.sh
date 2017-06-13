#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker build \
  --build-arg DOCKER_COMPOSE_VERSION=1.11.1 \
  --tag cyberdojofoundation/image_builder2 \
    ${MY_DIR}