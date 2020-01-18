#!/bin/bash -Ee

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
# This script is curl'd and run in CircleCI scripts.
# It
#   1) builds a language-test-framework image
#      eg cyberdojofoundation/java-junit
#      it gets the image name from SRC_DIR in...
#      - docker/image_name.json (if its a base image eg groovy)
#      - start_point/manifest.json (if its a test-framework image, eg groovy-junit)
#   2) builds a --languages start-points image
#      as created by a command such as
#         $ cyber-dojo start-point create NAME --languages SRC_DIR
#   3) tests it
#      - the start-point files from 2) are '9*6' tweaked to red/green/amber
#      - and passed to runner.run_cyber_dojo_sh()
#      - and inspect the returned colour
#   4) pushes the image built in 1) to dockerhub
#   5) notifies any dependent github projects
# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_NAME=$(basename $0)
readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SRC_DIR=${1:-${PWD}}
readonly TMP_DIR=$(mktemp -d /tmp/XXXXXX)

remove_tmp_dir()
{
  rm -rf "${TMP_DIR}" > /dev/null
}

# - - - - - - - - - - - - - - - - - -
trap_handler()
{
  remove_tmp_dir
  remove_start_point_image
  remove_runner
  remove_docker_network
}
trap trap_handler EXIT

# - - - - - - - - - - - - - - - - - -
exit_zero_if_show_help()
{
  if [ "${1}" == '-h' ] || [ "${1}" == '--help' ]; then
    show_use_long
    exit 0
  fi
}

# - - - - - - - - - - - - - - - - - -
exit_non_zero_unless_good_SRC_DIR()
{
  if [ ! -d "${SRC_DIR}" ]; then
    show_use_short
    echo "error: ${SRC_DIR} does not exist"
    exit 42
  fi
  if [ ! -f "${SRC_DIR}/docker/Dockerfile.base" ]; then
    show_use_short
    echo "error: ${SRC_DIR}/docker/Dockerfile.base does not exist"
    exit 42
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
show_use_short()
{
  echo "Use: ${MY_NAME} [SRC_DIR|-h|--help]"
  echo ''
  echo '  SRC_DIR defaults to ${PWD}'
  echo '  SRC_DIR/docker/Dockerfile.base must exist'
  echo ''
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
show_use_long()
{
  show_use_short
  echo 'Attempts to build a docker-image from ${SRC_DIR}/docker/Dockerfile.base'
  echo "(adjusted to fulfil the runner service's requirements)."
  echo ''
  echo '1. If ${SRC_DIR}/start_point/manifest.json exists, the name of the docker-image'
  echo 'will be taken from it, otherwise from ${SRC_DIR}/docker/image_name.json'
  echo ''
  echo '2. If ${SRC_DIR}/start_point/ exists:'
  echo '  *) Attempts to build a start-point image from the git-cloneable ${SRC_DIR}.'
  echo '     $ cyber-dojo start-point create ... --languages ${SRC_DIR}'
  echo '  *) Verifies the red->amber->green starting files progression'
  echo '     o) the starting-files give a red traffic-light.'
  echo '     o) with an introduced syntax error, give an amber traffic-light.'
  echo "     o) with '6 * 9' replaced by '6 * 7', give a green traffic-light."
  echo ''
  echo '3. If running on the CI/CD pipeine:'
  echo '  *) Pushes the docker-image to dockerhub'
  echo '  *) Triggers cyber-dojo-languages github repositories that use'
  echo '     the docker-image as their base (FROM) image.'
  echo
}

# - - - - - - - - - - - - - - - - - - - - -
ip_address()
{
  if [ -n "${DOCKER_MACHINE_NAME}" ]; then
    docker-machine ip ${DOCKER_MACHINE_NAME}
  else
    echo localhost
  fi
}

readonly IP_ADDRESS=$(ip_address)

#- - - - - - - - - - - - - - - - - - - - - - -
# path for cyber-dojo script
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
    exit 42
  fi
}

#- - - - - - - - - - - - - - - - - - - - - - -
# build the language-test-framework image (1)
#- - - - - - - - - - - - - - - - - - - - - - -
build_cdl_docker_image()
{
  # Create new Dockerfile containing extra
  # commands to fulfil the runner's requirements.
  echo "Building docker-image $(image_name)"
  cat "$(src_dir_abs)/docker/Dockerfile.base" \
    | \
      docker run \
        --interactive \
        --rm \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        cyberdojofoundation/image_dockerfile_augmenter \
    > \
      "$(src_dir_abs)/docker/Dockerfile"

  # Write new Dockerfile to stdout in case of debugging
  cat "$(src_dir_abs)/docker/Dockerfile"

  # Build the augmented docker-image.
  docker build \
    --file "$(src_dir_abs)/docker/Dockerfile" \
    --tag "$(image_name)" \
    "$(src_dir_abs)/docker"
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
has_start_point()
{
  [ -d "$(src_dir_abs)/start_point" ]
}

# - - - - - - - - - - - - - - - - - -
start_point_image_name()
{
  echo test_start_point_image
}

# - - - - - - - - - - - - - - - - - -
# start-point image which serves languages start-points
# - - - - - - - - - - - - - - - - - -
create_start_point_image()
{
  local -r name=$(start_point_image_name)
  echo "Building ${name}"
  eval $(script_path) start-point create "${name}" --languages "$(src_dir_abs)"
}

# - - - - - - - - - - - - - - - - - -
remove_start_point_image()
{
  docker image remove --force $(start_point_image_name) > /dev/null 2>&1 || true
}

# - - - - - - - - - - - - - - - - - -
check_red_amber_green()
{
  echo 'Checking red->amber->green progression'
  create_docker_network
  start_runner
  wait_until_ready runner "${CYBER_DOJO_RUNNER_PORT}"
  assert_traffic_light red
  assert_traffic_light amber
  assert_traffic_light green
}

# - - - - - - - - - - - - - - - - - - - - - - -
# network to host containers
# - - - - - - - - - - - - - - - - - - - - - - -
network_name()
{
  echo traffic-light
}

create_docker_network()
{
  echo "Creating network $(network_name)"
  local -r msg=$(docker network create $(network_name))
}

remove_docker_network()
{
  docker network remove $(network_name) > /dev/null 2>&1 || true
}

# - - - - - - - - - - - - - - - - - - - - - - -
# runner service to pass '6*9' starting files to
# - - - - - - - - - - - - - - - - - - - - - - -
runner_name()
{
  echo traffic-light-runner
}

remove_runner()
{
  docker rm --force $(runner_name) > /dev/null 2>&1 || true
}

start_runner()
{
  local -r image="${CYBER_DOJO_RUNNER_IMAGE}:${CYBER_DOJO_RUNNER_TAG}"
  local -r port="${CYBER_DOJO_RUNNER_PORT}"
  echo "Creating $(runner_name) service"
  local -r cid=$(docker run \
     --detach \
     --env NO_PROMETHEUS \
     --init \
     --name $(runner_name) \
     --network $(network_name) \
     --network-alias runner \
     --publish "${port}:${port}" \
     --read-only \
     --restart no \
     --tmpfs /tmp \
     --user root \
     --volume /var/run/docker.sock:/var/run/docker.sock \
       "${image}")
}

# - - - - - - - - - - - - - - - - - - - - -
readonly READY_FILENAME='/tmp/curl-ready-output'

wait_until_ready()
{
  local -r name="traffic-light-${1}"
  local -r port="${2}"
  local -r max_tries=20
  printf "Waiting until ${name} is ready"
  for _ in $(seq ${max_tries})
  do
    if ready ${port} ; then
      printf '.OK\n'
      return
    else
      printf .
      sleep 0.2
    fi
  done
  printf 'FAIL\n'
  echo "${name} not ready after ${max_tries} tries"
  if [ -f "${READY_FILENAME}" ]; then
    echo "$(cat "${READY_FILENAME}")"
  fi
  docker logs ${name}
  exit 42
}

# - - - - - - - - - - - - - - - - - - -
ready()
{
  local -r port="${1}"
  local -r path=ready?
  local -r curl_cmd="curl \
    --output ${READY_FILENAME} \
    --silent \
    --fail \
    --data {} \
    -X GET http://${IP_ADDRESS}:${port}/${path}"
  rm -f "${READY_FILENAME}"
  if ${curl_cmd} && [ "$(cat "${READY_FILENAME}")" = '{"ready?":true}' ]; then
    true
  else
    false
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
# check red->amber->green progression of '6*9'
# - - - - - - - - - - - - - - - - - - - - - - -
assert_traffic_light()
{
  local -r colour="${1}" # eg red
  docker run \
    --env NO_PROMETHEUS \
    --env SRC_DIR=$(src_dir_abs) \
    --init \
    --name traffic-light \
    --network $(network_name) \
    --read-only \
    --restart no \
    --rm \
    --tmpfs /tmp \
    --user nobody \
    --volume $(src_dir_abs):$(src_dir_abs):ro \
      cyberdojofoundation/image_hiker:latest "${colour}"
}

# - - - - - - - - - - - - - - - - - -
# notify github projects that use the built image as their base FROM image
# - - - - - - - - - - - - - - - - - -
notify_dependent_projects()
{
  echo 'Notifying dependent projects'

  local -r commit_push=github_automated_commit_push.sh
  local -r curled_path="${TMP_DIR}/${commit_push}"
  local -r github_org=https://raw.githubusercontent.com/cyber-dojo
  local -r url="${github_org}/cyber-dojo/master/circle-ci/${script_name}"

  curl \
    --fail \
    --output "${curled_path}" \
    --silent \
    "${url}"
  chmod 700 "${curled_path}"

  local -r from_org=cyber-dojo-languages
  local -r from_repo="${CIRCLE_PROJECT_REPONAME}" # eg java
  local -r from_sha="${CIRCLE_SHA1}" # eg a9334c964f81800a910dc3d301543262161fbbff
  local -r to_org=cyber-dojo-languages

  $(commit_push) \
    "${from_org}" "${from_repo}" "${from_sha}" \
    "${to_org}" $(dependent_projects)

  echo 'Successfully notified dependent projects'
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
check_version()
{
  "${SRC_DIR}/check_version.sh"
}

# - - - - - - - - - - - - - - - - - -
push_cdl_image_to_dockerhub()
{
  echo "Pushing $(image_name) to dockerhub"
  # DOCKER_PASSWORD, DOCKER_USERNAME must be in the CI context
  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
  docker push $(image_name)
  echo "Successfully pushed $(image_name) to dockerhub"
  docker logout
}

# - - - - - - - - - - - - - - - - - -
versioner_env_vars()
{
  docker run --rm cyberdojo/versioner:latest
}

# - - - - - - - - - - - - - - - - - -
export $(versioner_env_vars)
exit_zero_if_show_help $*
exit_non_zero_unless_good_SRC_DIR $*
build_cdl_docker_image
if has_start_point; then
  create_start_point_image
  check_red_amber_green
else
  check_version
fi
if on_CI && ! testing_myself; then
  push_cdl_image_to_dockerhub
  #notify_dependent_projects # not-live yet
else
  echo Not pushing image to dockerhub
  echo Not notifying dependent repos
fi
