#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly ORG_NAME=cyberdojofoundation
readonly TAG_NAME=$(basename ${MY_DIR})

docker login --username ${DOCKER_USERNAME} --password ${DOCKER_PASSWORD}

echo "For now, NOT doing [docker push ${ORG_NAME}/${TAG_NAME}]"
#docker push ${ORG_NAME}/${TAG_NAME}
