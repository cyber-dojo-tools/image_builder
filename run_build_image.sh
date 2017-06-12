#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
export WORK_DIR=${1:-`pwd`}

if [ ! -d "${WORK_DIR}" ]; then
  echo "FAILED: ${WORK_DIR} dir does not exist"
  exit 1
fi

# Can't call up.sh from .travis.yml
# because language repos curl only this script and up.sh
# lives in the image_builder repo.
# And up.sh in turn relies on docker-compose.yml
# Solutions?
# 1.
# Embed up.sh and docker-compose.yml inside the image_builder
# image, then this script can
#   docker pull cyberdojofoundation/image_builder
#   extract up.sh from it
#   extract docker-compose.yml from it
#
# 2. Put docker-compose inside image_builder (like commander)
# which has three services, builder,runner,runner_stateless

${MY_DIR}/up.sh

docker exec \
  --interactive \
  --tty \
  --env DOCKER_USERNAME \
  --env DOCKER_PASSWORD \
  --env GITHUB_TOKEN \
  --env WORK_DIR \
  cyber-dojo-image-builder /app/build_image.rb
