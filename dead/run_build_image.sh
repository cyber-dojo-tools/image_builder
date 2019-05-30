#!/bin/bash
set -e

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Checks cyber-dojo start-point source living in SRC_DIR
#
#  o) build a docker-image satisfying runner's requirements
#     /docker
#  o) check start-point files are valid
#     /start_point
#  o) check red-amber-green progression of starting files
#     /docker and /start_point
#
# This script is curl'd and run in the Travis/CircleCI scripts
# of all cyber-dojo-language (github org) repos.
# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# assumes following dir layout if running locally and offline.
# .../cyber-dojo/commander
# .../cyber-dojo-languages/image_builder
# .../cyber-dojo-languages/gcc-assert

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SRC_DIR=${1:-${PWD}}
readonly TMP_DIR=$(mktemp -d /tmp/cyber-dojo-custom.XXXXXXXXX)

readonly NETWORK=src_dir_network  # will die
readonly NAME=src_dir_container   # will die
readonly SCRIPT_NAME=cyber-dojo

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
  #        expand it based on PWD ?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

show_use_long()
{
  show_use_short
  echo 'Creates the docker-image'
  echo '-----------------------'
  echo 'If SRC_DIR/docker/ exists this script will verify a docker-image'
  echo 'can be created from its Dockerfile, with suitable adjustments to'
  echo "fulfil to the runner's requirements."
  echo 'If SRC_DIR/start_point/manifest.json exists the name of the'
  echo 'docker-image will be taken from it, otherwise from'
  echo 'SRC_DIR/docker/image_name.json'
  echo
  echo 'Creates the start-point image'
  echo '----------------------------'
  echo 'If SRC_DIR/start_point/ exists this script will verify a cyber-dojo'
  echo 'start-point image can be created from SRC_DIR, which must be a git-repo,'
  echo 'viz'
  echo '  $ cyber-dojo start-point create ... --languages ${SRC_DIR}'
  echo
  echo 'Checks the red->amber->green start files progression'
  echo '---------------------------------------------------'
  echo 'If SRC_DIR/docker/ and SRC_DIR/start_point/ exist this script will verify'
  echo 'o) the starting-files give a red traffic-light'
  echo 'o) with an introduced syntax error, give an amber traffic-light'
  echo "o) with '9 * 6' replaced by '9 * 7', give a green traffic-light"
  echo
}

#- - - - - - - - - - - - - - - - - - - - - - -

docker_dir()
{
  echo "${SRC_DIR}/docker"
}

docker_dir_exists()
{
  [ -d "$(docker_dir)" ]
}

#- - - - - - - - - - - - - - - - - - - - - - -

start_point_dir()
{
  echo "${SRC_DIR}/start_point"
}

start_point_dir_exists()
{
  [ -d "$(start_point_dir)" ]
}

#- - - - - - - - - - - - - - - - - - - - - - -

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

#- - - - - - - - - - - - - - - - - - - - - - -

script_path()
{
  local STRAIGHT_PATH=`absPath "${MY_DIR}/../../cyber-dojo/commander/${SCRIPT_NAME}"`
  local CURLED_PATH="${TMP_DIR}/${SCRIPT_NAME}"

  if [ -f "${STRAIGHT_PATH}" ]; then
    echo "${STRAIGHT_PATH}"
  elif [ ! -f "${CURLED_PATH}" ]; then
    local GITHUB_ORG=https://raw.githubusercontent.com/cyber-dojo
    local REPO_NAME=commander
    local URL="${GITHUB_ORG}/${REPO_NAME}/master/${SCRIPT_NAME}"
    curl --silent --fail "${URL}" > "${CURLED_PATH}"
    chmod 700 "${CURLED_PATH}"
    echo "${CURLED_PATH}"
  else
    echo "${CURLED_PATH}"
  fi
}

tmp_dir_remove()
{
  rm -rf ${TMP_DIR} > /dev/null;
}

#- - - - - - - - - - - - - - - - - - - - - - -

show_location()
{
  echo "Running with $(script_path)"
}

#- - - - - - - - - - - - - - - - - - - - - - -

network_create() # will die
{
  NETWORK_CREATED=false
  docker network create ${NETWORK} > /dev/null
  NETWORK_CREATED=true
}

network_remove() # will die
{
  if "${NETWORK_CREATED}" == "true"; then
    echo 'clean-up: [docker network rm]'
    docker network rm ${NETWORK} > /dev/null
  fi
}

# - - - - - - - - - - - - - - - - - -

volume_create() # will die
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

volume_remove() # will die
{
  if "${VOLUME_CREATED}" == "true"; then
    echo 'clean-up: [docker volume rm]'
    docker volume rm --force ${NAME} > /dev/null
    docker rm ${NAME} > /dev/null
  fi
}

# - - - - - - - - - - - - - - - - - -

build_image() # will die
{
  docker run \
    --user=root \
    --network=${NETWORK} \
    --rm \
    --tty \
    --init \
    --interactive \
    --env DOCKER_USERNAME \
    --env DOCKER_PASSWORD \
    --env GITHUB_TOKEN \
    --env SRC_DIR=${SRC_DIR} \
    --env TRAVIS \
    --env TRAVIS_REPO_SLUG \
    --env TRAVIS_EVENT_TYPE \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
      cyberdojofoundation/image_builder \
        /app/outer_main.rb $*
}

# - - - - - - - - - - - - - - - - - -

exit_handler()
{
  tmp_dir_remove
  volume_remove  # will die
  network_remove # will die
}

# - - - - - - - - - - - - - - - - - -

check_use $*
show_location

# TODO: I think a docker/ dir HAS to exist...
if docker_dir_exists; then
  echo "# trying to create docker-image..."
  # TODO: Embed and use build_image() from ./src/build_image.sh
  trap exit_handler INT EXIT # TODO: move outside of if
  volume_create
  network_create
  build_image $*
  echo '# docker-image can be created'
fi

if start_point_dir_exists; then
  echo "# trying to create a start-point image..."
  $(script_path) start-point create jj1 --languages "${SRC_DIR}"
  $(script_path) start-point rm jj1
  echo '# start-point image can be created'
fi

if docker_dir_exists && start_point_dir_exists; then
  echo "Checking red->amber->green progression..."
  #...TODO (will use cyber-dojo/hiker service)
fi

#TODO
#if on_CI && !cron_job; then
#  ./src/notify_dependents.sh "${SRC_DIR}"
#fi
