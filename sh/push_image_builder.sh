#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"
readonly ORG_NAME=cyberdojofoundation
readonly TAG_NAME=$(basename ${ROOT_DIR})

docker login --username ${DOCKER_USERNAME} --password ${DOCKER_PASSWORD}

docker push ${ORG_NAME}/image_builder_inner
docker push ${ORG_NAME}/image_builder
