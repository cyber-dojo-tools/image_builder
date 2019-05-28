#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly IMAGE_NAME=cyberdojo/get_dockerfile

# path to Dockerfile will be in $1

cat "${MY_DIR}/Dockerfile" \
  | docker run --rm \
      --interactive \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      "${IMAGE_NAME}"
