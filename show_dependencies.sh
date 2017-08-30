#!/bin/bash

readonly SRC_DIR=${1:-${PWD}}
readonly NETWORK=src_dir_network
readonly NAME=src_dir_container

if [ ! -z "${TRAVIS}" ]; then
  #echo 'Running on TRAVIS'
  readonly BASE_DIR=${SRC_DIR}
else
  #echo 'Running locally'
  readonly BASE_DIR=$(dirname ${SRC_DIR})
fi

# I create a data-volume-container which holds src-dir/..
# By default this lives on one network and the containers
# created inside image_builder (from its docker-compose.yml file)
# live on a different network, and thus the later won't be able
# to see to the former. To solve this I'm putting the src-dir/..
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
  --env TRAVIS_REPO_SLUG \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
    cyberdojofoundation/image_builder \
      /app/outer_show_dependencies.rb

exit_status=$?

docker rm --force --volumes ${NAME} > /dev/null

docker network rm ${NETWORK} > /dev/null

#echo "exit_status=${exit_status}"
exit ${exit_status}
