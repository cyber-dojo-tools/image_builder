#!/bin/bash

WORK_DIR=${1:-`PWD`}

if [ ! -d "${WORK_DIR}" ]; then
  echo "FAILED: ${WORK_DIR} dir does not exist"
  exit 1
fi

docker run \
    --rm \
    --interactive \
    --tty \
    --env DOCKER_USERNAME=${DOCKER_USERNAME} \
    --env DOCKER_PASSWORD=${DOCKER_PASSWORD} \
    --env WORK_DIR=${WORK_DIR} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=${WORK_DIR}:/language:ro \
    cyberdojofoundation/image_builder \
      ./build_image.rb
