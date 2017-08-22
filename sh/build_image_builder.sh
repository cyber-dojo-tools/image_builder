#!/bin/bash
set -e

# This builds the main 'outer' image_builder docker-image
# which includes docker-compose inside it.

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

docker build \
  --build-arg DOCKER_COMPOSE_VERSION=1.11.1 \
  --tag cyberdojofoundation/image_builder \
    ${ROOT_DIR}

${ROOT_DIR}/builder/build-docker-image.sh