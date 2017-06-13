#!/bin/bash
set -e

# Runs image-builder on source living in SRC_DIR which
# can be passed as $1 and defaults to the current work directory.

readonly SRC_DIR=${1:-`pwd`}

docker run \
   --user=root \
   --rm \
   --interactive \
   --tty \
   --env DOCKER_USERNAME \
   --env DOCKER_PASSWORD \
   --env SRC_DIR=${SRC_DIR} \
   --volume=${SRC_DIR}:${SRC_DIR}:ro \
   --volume=/var/run/docker.sock:/var/run/docker.sock \
     cyberdojofoundation/image_builder2 \
       /app/build_image.sh
