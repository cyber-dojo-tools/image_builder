#!/bin/bash
set -e

# Runs image-builder on source living in SRC_DIR which
# can be passed as $1 but defaults to the current work directory.
# This script is curl'd and run as the only command in each
# language's .travis.yml script.

readonly SRC_DIR=${1:-`pwd`}

if [ ! -d "${SRC_DIR}" ]; then
  echo "${SRC_DIR} does not exist"
  exit 1
fi

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
    cyberdojofoundation/image_builder \
      /app/build_image.rb
