#!/bin/bash
set -e

# This builds the main 'outer' image_builder docker-image
# which includes docker-compose inside it.

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker build \
  --build-arg DOCKER_COMPOSE_VERSION=1.11.1 \
  --tag cyberdojofoundation/image_builder \
    ${MY_DIR}
