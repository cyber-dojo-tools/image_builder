#!/bin/bash
set -e

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Runs image-builder on source living in SRC_DIR to
#   o) build zero or more docker-images
#   o) test zero or more start-point directories.
#
# This script is curl'd and run in the .travis.yml script
# of each cyber-dojo-language (github org) repo.
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly SRC_DIR=${1:-${PWD}}
readonly NETWORK=src_dir_network
readonly NAME=src_dir_container

check_use()
{
  if [ "${1}" == '--help' ]; then
    show_use_long
    exit 1
  fi
  if [ ! -d "${SRC_DIR}" ]; then
    show_use_short
    echo "error: SRC_DIR <${SRC_DIR}> does not exist"
    exit 1
  fi
}

show_use_short()
{
  echo "Use: $(basename $0) [SRC_DIR|--help]"
  echo ''
  echo '  SRC_DIR defaults to ${PWD}'
  echo '  SRC_DIR must be an absolute path'
  echo ''
  # TODO?: SRC_DIR must be absolute because you cant create
  #        a docker-volume from a relative path.
  #        Check if $SRC_DIR is relative and if it is
  #       expand it based on PWD ?
}

show_use_long()
{
  show_use_short
  echo 'If SRC_DIR/start_point_type.json exists this script will'
  echo 'verify that a cyber-dojo start-point can be created from SRC_DIR, viz'
  echo '  $ cyber-dojo start-point create ... --dir=${SRC_DIR}'
  echo ''
  echo 'If SRC_DIR (or any sub-dir) contains a Dockerfile this script will'
  echo 'verify, for each one, that a docker-image can be created from it.'
  echo ''
  echo 'If SRC_DIR (or any sub-dir) contains a manifest.json this script will'
  echo 'verify, for each one, that a start-point entry can be created from it.'
  echo ''
  echo 'In each Dockerfile dir there must be an image_name.json specifying'
  echo 'the name of docker image to create from the Dockerfile. However,'
  echo 'if there is a single Dockerfile and a single manifest.json then the'
  echo 'name of the docker image will be taken from the manifest.json file.'
}

#- - - - - - - - - - - - - - - - - - - - - - -

show_location()
{
  if [ ! -z "${TRAVIS}" ]; then
    echo 'Running on TRAVIS'
  else
    echo 'Running locally'
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - -

network_create()
{
  NETWORK_CREATED=false
  docker network create ${NETWORK} > /dev/null
  NETWORK_CREATED=true
}

network_remove()
{
  if "${NETWORK_CREATED}" == "true"; then
    echo 'clean-up: [docker network rm]'
    docker network rm ${NETWORK} > /dev/null
  fi
}

# - - - - - - - - - - - - - - - - - -

volume_create()
{
  # I create a data-volume-container which holds src-dir
  # By default this lives on one network and the containers
  # created _inside_ image_builder (from its docker-compose.yml file)
  # live on a different network, and thus the later won't be able
  # to see to the former. To solve this I'm putting the src-dir
  # data-volume-container into its own dedicated network.
  VOLUME_CREATED=false
  docker create \
    --volume=${SRC_DIR}:${SRC_DIR} \
    --name=${NAME} \
    --network=${NETWORK} \
    cyberdojofoundation/image_builder \
      /bin/true > /dev/null
  VOLUME_CREATED=true
}

volume_remove()
{
  if "${VOLUME_CREATED}" == "true"; then
    echo 'clean-up: [docker volume rm]'
    docker volume rm --force ${NAME} > /dev/null
    docker rm ${NAME} > /dev/null
  fi
}

# - - - - - - - - - - - - - - - - - -

run()
{
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
}

# - - - - - - - - - - - - - - - - - -

exit_handler()
{
  volume_remove
  network_remove
}

check_use $*
trap exit_handler INT EXIT
show_location
volume_create
network_create
run
