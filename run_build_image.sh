#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
export WORK_DIR=${1:-`pwd`}

if [ ! -d "${WORK_DIR}" ]; then
  echo "FAILED: ${WORK_DIR} dir does not exist"
  exit 1
fi

${MY_DIR}/up.sh

docker exec \
  --interactive \
  --tty \
  --env DOCKER_USERNAME \
  --env DOCKER_PASSWORD \
  --env GITHUB_TOKEN \
  --env WORK_DIR \
  cyber-dojo-image-builder /app/build_image.rb
