#!/bin/bash

# Runs image-builder on source living in SRC_DIR.
# This script is curl'd and run as the only command in each
# cyber-dojo-language repo's .travis.yml script.

show_use() {
  echo 'Use: run_build_image.sh <SRC_DIR> '
  echo ''
  echo '  <SRC_DIR> defaults to ${PWD}'
  echo ''
}

readonly SRC_DIR=${1:-${PWD}}
readonly NETWORK=src_dir_network
readonly NAME=src_dir_container

if [ -z "${SRC_DIR}" ] || [ "${1}" == '--help' ]; then
  show_use
  exit 1
fi

if [ ! -d "${SRC_DIR}" ]; then
  show_use
  echo "SRC_DIR <${SRC_DIR}> does not exist"
  exit 1
fi

shift # ${1}

if [ ! -z "${TRAVIS}" ]; then
  echo 'Running on TRAVIS'
else
  echo 'Running locally'
fi

# I create a data-volume-container which holds src-dir
# By default this lives on one network and the containers
# created inside image_builder (from its docker-compose.yml file)
# live on a different network, and thus the later won't be able
# to see to the former. To solve this I'm putting the src-dir
# data-volume-container into its own dedicated network.

docker network create ${NETWORK} > /dev/null

docker create \
  --volume=${SRC_DIR}:${SRC_DIR} \
  --name=${NAME} \
  --network=${NETWORK} \
  cyberdojofoundation/image_builder \
    /bin/true > /dev/null

docker run \
  --user=root \
  --network=${NETWORK} \
  --rm \
  --interactive \
  --tty \
  --env DOCKER_USERNAME \
  --env DOCKER_PASSWORD \
  --env GITHUB_TOKEN \
  --env SRC_DIR=${SRC_DIR} \
  --env TRAVIS \
  --env TRAVIS_REPO_SLUG \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
    cyberdojofoundation/image_builder \
      /app/outer_main.rb

readonly exit_status=$?

docker rm --force --volumes ${NAME}

docker network rm ${NETWORK}

echo "exit_status=${exit_status}"
exit ${exit_status}
