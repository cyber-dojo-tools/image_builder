#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly BASE_IMAGE_NAME=cyberdojo/get_dockerfile

"${MY_DIR}/build_base_docker_image.sh" "${BASE_IMAGE_NAME}"

readonly TARGET_DIR=${MY_DIR} # will be $1
readonly IMAGE_NAME=tryit     # will be via another tool on $1

cd "${TARGET_DIR}" \
&& \
cat "./Dockerfile" \
  | \
    docker run --rm \
      --interactive \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "${BASE_IMAGE_NAME}" \
  | \
    docker build --tag "${IMAGE_NAME}" -
