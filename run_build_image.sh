#!/bin/bash

WORK_DIR=${1:-`pwd`}

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
    --env GITHUB_TOKEN=${GITHUB_TOKEN} \
    --env WORK_DIR=${WORK_DIR} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=${WORK_DIR}:/repo:ro \
    cyberdojofoundation/image_builder \
      ./build_image.rb
