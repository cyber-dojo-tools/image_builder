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

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SRC_DIR=${1:-${PWD}}
readonly TMP_DIR=$(mktemp -d)
readonly CONTEXT_DIR=$(mktemp -d)
readonly SCRIPT_NAME=cyber-dojo

remove_tmp_dirs()
{
  rm -rf "${CONTEXT_DIR}" > /dev/null
  rm -rf "${TMP_DIR}" > /dev/null;
}

exit_handler()
{
  remove_tmp_dirs
}

trap exit_handler INT EXIT

# - - - - - - - - - - - - - - - - - -

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
  echo ''
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

#- - - - - - - - - - - - - - - - - - - - - - -

build_image()
{
  local START_POINT_DIR=`absPath "${SRC_DIR}"`

  # Find the name of the docker-image.
  local IMAGE_NAME=$(docker run \
    --rm \
    --interactive \
    --volume "${START_POINT_DIR}:/data:ro" \
    cyberdojo/image_namer)

  # Copy the docker/ dir into a new temporary context-dir
  # so we can overwrite its Dockerfile.
  cp -R "${START_POINT_DIR}/docker" "${CONTEXT_DIR}"

  # Overwrite the Dockerfile with one containing
  # extra commands to fulfil the runner's requirements.
  cat "${START_POINT_DIR}/docker/Dockerfile" \
    | \
      docker run --rm \
        --interactive \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        cyberdojo/dockerfile_augmenter \
    > \
      "${CONTEXT_DIR}/Dockerfile"

  # Write new Dockerfile to stdout in case of debugging
  echo '# ~~~~~~~~~~~~~~~~~~~~~~~~~'
  cat "${CONTEXT_DIR}/Dockerfile"
  echo '# ~~~~~~~~~~~~~~~~~~~~~~~~~'

  # Build the augmented docker-image.
  docker build \
    --tag "${IMAGE_NAME}" \
    "${CONTEXT_DIR}/docker"
}

# - - - - - - - - - - - - - - - - - -

on_CI()
{
  [ "${TRAVIS}" = 'true' ]
}

CI_cron_job()
{
  [ "${TRAVIS_EVENT_TYPE}" = 'cron' ]
}

notify_dependents()
{
  local START_POINT_DIR=`absPath "${SRC_DIR}"`
  docker run \
    --env DOCKER_USERNAME \
    --env DOCKER_PASSWORD \
    --env GITHUB_TOKEN \
    --env TRAVIS \
    --env TRAVIS_EVENT_TYPE \
    --env TRAVIS_REPO_SLUG \
    --interactive \
    --rm \
    --volume "${START_POINT_DIR}:/data:ro" \
      cyberdojo/dependents_notifier
}

# - - - - - - - - - - - - - - - - - -

docker_dir()
{
  echo "${SRC_DIR}/docker"
}

start_point_dir()
{
  echo "${SRC_DIR}/start_point"
}

# - - - - - - - - - - - - - - - - - -

check_use $*
echo "Running with $(script_path)"

if [ ! -d "$(docker_dir)" ]; then
  echo "error: $(docker_dir)/ does not exist"
  exit 1
fi

echo "# trying to create docker-image..."
build_image
echo '# docker-image can be created'

if [ -d "$(start_point_dir)" ]; then
  echo "# trying to create a start-point image..."
  $(script_path) start-point create jj1 --languages "${SRC_DIR}"
  $(script_path) start-point rm jj1
  echo '# start-point image can be created'

  echo "Checking red->amber->green progression..."
  #...TODO (will use cyber-dojo/hiker service)
fi

if on_CI && !CI_cron_job; then
  notify_dependents
fi
