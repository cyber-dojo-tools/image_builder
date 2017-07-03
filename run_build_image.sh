#!/bin/bash

# Runs image-builder on source living in SRC_DIR which is passed as $1.
# This script is curl'd and run as the only command in each
# cyber-dojo-language repo's .travis.yml script.

show_use() {
  echo 'Use: run_build_image.sh <SRC_DIR> [options...]'
  echo 'Options:'
  echo '  --push=true    Login to dockerhub and push good images'
  echo ''
  echo 'Example: ./run_build_image.sh ${PWD}'
}

readonly SRC_DIR=${1}
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

if [ -z "${TRAVIS}" ]; then
  echo "Running locally"
  readonly BASE_DIR=$(dirname ${SRC_DIR})
else
  echo 'Running on TRAVIS'
  readonly BASE_DIR=${SRC_DIR}
fi

# I create a data-volume-container which holds src-dir/..
# By default this lives on one network and the containers
# created inside image_builder (from its docker-compose.yml file)
# live on a different network, and thus the later won't be able
# to connect to the former. To solve this I'm putting the src-dir/..
# data-volume-container into its own dedicated network.

docker network create ${NETWORK} > /dev/null

docker create \
  --volume=${BASE_DIR}:${BASE_DIR} \
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
  --volume=/var/run/docker.sock:/var/run/docker.sock \
    cyberdojofoundation/image_builder \
      /app/build_image.rb ${*}

exit_status=$?

docker rm --force --volumes ${NAME}

docker network rm ${NETWORK}

echo "exit_status=${exit_status}"
exit ${exit_status}
