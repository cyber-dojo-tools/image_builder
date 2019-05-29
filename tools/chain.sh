#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

readonly DOCKER_DIR=${1}
readonly IMAGE_NAME=${2}

cd "${DOCKER_DIR}" \
&& \
"${MY_DIR}/augmented_Dockerfile.sh" "${DOCKER_DIR}" \
| \
docker build --tag "${IMAGE_NAME}" -
