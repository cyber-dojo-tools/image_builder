#!/bin/bash
set -e

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# This script is curl'd and run in the Travis/CircleCI scripts
# of all cyber-dojo-language (github org) repos.
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SRC_DIR=${1:-${PWD}}
readonly TMP_DIR=$(mktemp -d)
readonly CONTEXT_DIR=$(mktemp -d)
readonly SCRIPT_NAME=cyber-dojo # TODO: used?

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
    exit 0
  fi
  if [ ! -d "${SRC_DIR}" ]; then
    show_use_short
    echo 'error: ${SRC_DIR} does not exist'
    echo "${SRC_DIR}"
    exit 1
  fi
  if [ ! -d "${SRC_DIR}/docker" ]; then
    show_use_short
    echo 'error: ${SRC_DIR}/docker does not exist'
    echo "${SRC_DIR}/docker"
    exit 1
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

show_use_short()
{
  echo "Use: $(basename $0) [SRC_DIR|--help]"
  echo ''
  echo '  SRC_DIR defaults to ${PWD}'
  echo '  SRC_DIR must have a docker/ sub-dir'
  echo ''
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

show_use_long()
{
  show_use_short
  echo 'Attempts to build a docker-image from ${SRC_DIR}/docker/Dockerfile'
  echo "adjusted to fulfil the runner service's requirements."
  echo 'If ${SRC_DIR}/start_point/manifest.json exists the name of the docker-image'
  echo 'will be taken from it, otherwise from ${SRC_DIR}/docker/image_name.json'
  echo
  echo 'If ${SRC_DIR}/start_point/ exists:'
  echo '  1. Attempts to build a start-point image from the git-cloneable ${SRC_DIR}.'
  echo '     $ cyber-dojo start-point create ... --languages ${SRC_DIR}'
  echo '  2. Verifies the red->amber->green starting files progression'
  echo '     o) the starting-files give a red traffic-light'
  echo '     o) with an introduced syntax error, give an amber traffic-light'
  echo "     o) with '6 * 9' replaced by '6 * 7', give a green traffic-light"
  echo
}

#- - - - - - - - - - - - - - - - - - - - - - -

script_path()
{
  local STRAIGHT_PATH="${MY_DIR}/../../cyber-dojo/commander/${SCRIPT_NAME}"
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

src_dir_abs()
{
  # docker volume-mounts cannot be relative
  cd "$(dirname "${SRC_DIR}")"
  printf "%s/%s\n" "$(pwd)" "$(basename "${SRC_DIR}")"
}

#- - - - - - - - - - - - - - - - - - - - - - -

build_image()
{
  # Find the name of the docker-image.
  local IMAGE_NAME=$(docker run \
    --rm \
    --interactive \
    --volume "$(src_dir_abs):/data:ro" \
    cyberdojo/image_namer)

  # Copy the docker/ dir into a new temporary context-dir
  # so we can overwrite its Dockerfile.
  cp -R "$(src_dir_abs)/docker" "${CONTEXT_DIR}"

  # Overwrite the Dockerfile with one containing
  # extra commands to fulfil the runner's requirements.
  cat "$(src_dir_abs)/docker/Dockerfile" \
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
  docker run \
    --env DOCKER_USERNAME \
    --env DOCKER_PASSWORD \
    --env GITHUB_TOKEN \
    --env TRAVIS \
    --env TRAVIS_EVENT_TYPE \
    --env TRAVIS_REPO_SLUG \
    --interactive \
    --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(src_dir_abs):/data:ro" \
      cyberdojo/dependents_notifier
}

# - - - - - - - - - - - - - - - - - -

check_use $*
echo "# trying to create docker-image..."
build_image
echo '# docker-image can be created'

if [ -d "$(src_dir_abs)/start_point" ]; then
  echo "# trying to create a start-point image..."
  $(script_path) start-point create jj1 --languages "$(src_dir_abs)"
  $(script_path) start-point rm jj1
  echo '# start-point image can be created'

  echo 'checking red->amber->green progression...'
  #...TODO (will use cyber-dojo/hiker service)
fi

if on_CI && ! CI_cron_job; then
  #TODO: docker login, docker push IMAGE_NAME, docker logout HERE
  notify_dependents
fi
