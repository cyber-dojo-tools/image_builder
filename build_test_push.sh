#!/bin/bash
set -e

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# This script is curl'd and run in CircleCI scripts. It
#   o) builds a cyber-dojo-language image
#   o) tests it
#   o) pushes it to dockerhub
#   o) notifies any dependent repos
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SRC_DIR=${1:-${PWD}}
readonly TMP_DIR=$(mktemp -d)
readonly TMP_CONTEXT_DIR=$(mktemp -d)

remove_tmp_dirs()
{
  rm -rf "${TMP_CONTEXT_DIR}" > /dev/null
  rm -rf "${TMP_DIR}" > /dev/null;
}

exit_handler()
{
  remove_tmp_dirs
}

trap exit_handler INT EXIT

# - - - - - - - - - - - - - - - - - -

gap()
{
  for i in {1..5}; do echo '.'; done
}

line()
{
  for i in {1..80}; do echo -n '='; done
  echo
}

banner()
{
  line
  echo "${1}"
  line
}

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
    exit 3
  fi
  if [ ! -d "${SRC_DIR}/docker" ]; then
    show_use_short
    echo 'error: ${SRC_DIR}/docker does not exist'
    echo "${SRC_DIR}/docker"
    exit 3
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
  local -r script_name=cyber-dojo
  # Run locally when offline
  local -r local_path="${MY_DIR}/../../cyber-dojo/commander/${script_name}"
  local -r curled_path="${TMP_DIR}/${script_name}"

  if on_CI && [ ! -f "${curled_path}" ]; then
    local -r github_org=https://raw.githubusercontent.com/cyber-dojo
    local -r repo_name=commander
    local -r url="${github_org}/${repo_name}/master/${script_name}"
    curl --silent --fail "${url}" > "${curled_path}"
    chmod 700 "${curled_path}"
    echo "${curled_path}"
  elif on_CI && [ -f "${curled_path}" ]; then
    echo "${curled_path}"
  elif [ -f "${local_path}" ]; then
    local -r env_var=COMMANDER_IMAGE=cyberdojo/commander:latest
    echo "${env_var} ${local_path}"
  else
    >&2 echo 'FAILED: Not a CI/CD run so expecting cyber-dojo script in dir at:'
    >&2 echo "${MY_DIR}/../../cyber-dojo/commander"
    exit 3
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

image_name()
{
  docker run \
    --interactive \
    --rm \
    --volume "$(src_dir_abs):/data:ro" \
    cyberdojofoundation/image_namer
}

#- - - - - - - - - - - - - - - - - - - - - - -

build_image()
{
  # Copy the docker/ dir into a new temporary context-dir
  # so we can overwrite its Dockerfile.
  cp -R "$(src_dir_abs)/docker" "${TMP_CONTEXT_DIR}"

  # Overwrite the Dockerfile with one containing
  # extra commands to fulfil the runner's requirements.
  cat "$(src_dir_abs)/docker/Dockerfile" \
    | \
      docker run \
        --interactive \
        --rm \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        cyberdojofoundation/dockerfile_augmenter \
    > \
      "${TMP_CONTEXT_DIR}/docker/Dockerfile"

  # Write new Dockerfile to stdout in case of debugging
  cat "${TMP_CONTEXT_DIR}/docker/Dockerfile"
  echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'

  # Build the augmented docker-image.
  docker build \
    --tag "$(image_name)" \
    "${TMP_CONTEXT_DIR}/docker"
}

# - - - - - - - - - - - - - - - - - -

on_CI()
{
  [ -n "${CIRCLE_SHA1}" ]
}

testing_myself()
{
  # Don't push CDL images or notify dependent repos
  # if building CDL images as part of image_builders own tests.
  [ "${CIRCLE_PROJECT_REPONAME}" = 'image_builder' ]
}

notify_dependent_repos()
{
  docker run \
    --env CIRCLE_API_MACHINE_USER_TOKEN \
    --interactive \
    --rm \
    --volume "$(src_dir_abs):/data:ro" \
      cyberdojofoundation/dependents_notifier
}

# - - - - - - - - - - - - - - - - - -

check_use $*
echo
banner "Creating docker-image $(image_name)"
build_image
banner "Successfully created docker-image $(image_name)"
gap

if [ -d "$(src_dir_abs)/start_point" ]; then
  banner "Creating a start-point image..."
  eval $(script_path) start-point create jj1 --languages "$(src_dir_abs)"
  eval $(script_path) start-point rm jj1
  banner 'Successfully created start-point image'
  gap
  banner 'Checking red->amber->green progression (TODO)'
  #...TODO (will use cyber-dojo/hiker service)
else
  "${SRC_DIR}/check_version.sh"
fi

if on_CI && ! testing_myself; then
  gap
  banner "Pushing $(image_name) to dockerhub"
  docker push $(image_name)
  banner "Successfully pushed $(image_name) to dockerhub"
  gap
  banner 'Notifying dependent repos'
  notify_dependent_repos
  banner 'Successfully notified dependent repos'
fi

echo
