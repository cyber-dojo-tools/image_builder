#!/bin/bash
set -e

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# This script is curl'd and run in CircleCI scripts. It
#   o) builds a cyber-dojo-language image
#   o) tests it
#   o) pushes it to dockerhub
#   o) notifies any dependent CircleCI projects
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_NAME=$(basename $0)
readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SRC_DIR=${1:-${PWD}}
readonly TMP_DIR=$(mktemp -d /tmp/XXXXXX)

remove_tmp_dir()
{
  rm -rf "${TMP_DIR}" > /dev/null;
}

trap remove_tmp_dir INT EXIT

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
  if [ "${1}" = '-h' ] || [ "${1}" = '--help' ]; then
    show_use_long
    exit 0
  fi
  if [ ! -d "${SRC_DIR}" ]; then
    show_use_short
    echo "error: ${SRC_DIR} does not exist"
    exit 3
  fi
  if [ ! -f "${SRC_DIR}/Dockerfile" ]; then
    show_use_short
    echo "error: ${SRC_DIR}/Dockerfile does not exist"
    exit 3
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

show_use_short()
{
  echo "Use: ${MY_NAME} [SRC_DIR|--help]"
  echo ''
  echo '  SRC_DIR defaults to ${PWD}'
  echo '  SRC_DIR must have a Dockerfile'
  echo ''
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

show_use_long()
{
  show_use_short
  echo 'Attempts to build a docker-image from ${SRC_DIR}/Dockerfile'
  echo "adjusted to fulfil the runner service's requirements."
  echo 'If ${SRC_DIR}/start_point/manifest.json exists the name of the docker-image'
  echo 'will be taken from it, otherwise from ${SRC_DIR}/image_name.json'
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
  echo $(cd ${SRC_DIR} && pwd)
}

#- - - - - - - - - - - - - - - - - - - - - - -

image_name()
{
  docker run \
    --rm \
    --volume "$(src_dir_abs):/data:ro" \
    cyberdojofoundation/image_namer
}

#- - - - - - - - - - - - - - - - - - - - - - -

build_image()
{
  # Create new Dockerfile containing extra
  # commands to fulfil the runner's requirements.
  cat "$(src_dir_abs)/Dockerfile" \
    | \
      docker run \
        --interactive \
        --rm \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        cyberdojofoundation/image_dockerfile_augmenter \
    > \
      "${TMP_DIR}/Dockerfile"

  # Write new Dockerfile to stdout in case of debugging
  cat "${TMP_DIR}/Dockerfile"
  echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'

  # Build the augmented docker-image.
  docker build \
    --file "${TMP_DIR}/Dockerfile" \
    --tag "$(image_name)" \
    "$(src_dir_abs)"
}

# - - - - - - - - - - - - - - - - - -

dependent_projects()
{
  docker run \
    --rm \
    --volume "$(src_dir_abs):/data:ro" \
      cyberdojofoundation/image_dependents
}

# - - - - - - - - - - - - - - - - - -

notify_dependent_projects()
{
  local -r repos=$(dependent_projects)
  docker run \
    --env CIRCLE_API_MACHINE_USER_TOKEN \
    --rm \
      cyberdojofoundation/image_notifier \
        ${repos}
}

# - - - - - - - - - - - - - - - - - -

on_CI()
{
  [ -n "${CIRCLE_SHA1}" ]
}

# - - - - - - - - - - - - - - - - - -

testing_myself()
{
  # Don't push CDL images or notify dependent repos
  # if building CDL images as part of image_builder's own tests.
  [ "${CIRCLE_PROJECT_REPONAME}" = 'image_builder' ]
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
  #...TODO (will use cyber-dojo-languages/hiker service)
else
  "${SRC_DIR}/check_version.sh"
fi

if on_CI && ! testing_myself; then
  gap
  banner "Pushing $(image_name) to dockerhub"
  docker push $(image_name)
  banner "Successfully pushed $(image_name) to dockerhub"
  gap
  banner 'Notifying dependent projects'
  notify_dependent_projects
  banner 'Successfully notified dependent projects'
fi

echo
