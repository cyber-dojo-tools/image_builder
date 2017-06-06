#!/bin/bash
set -e

docker login --username ${DOCKER_USERNAME} --password ${DOCKER_PASSWORD}
ORG_NAME=cyberdojofoundation
TAG_NAME=$(basename ${TRAVIS_REPO_SLUG})
docker push ${ORG_NAME}/${TAG_NAME}
