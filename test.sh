#!/bin/bash
set -e

check_up()
{
  set +e
  local up=$(docker ps --filter status=running --format '{{.Names}}' | grep ^${1}$)
  set -e
  if [ "${up}" != "${1}" ]; then
    echo
    echo "${1} exited"
    docker logs ${1}
    exit 1
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly NAME=language

docker volume create --name=${NAME}

readonly docker_compose="docker-compose --file ${MY_DIR}/docker-compose.yml"

${docker_compose} up -d runner
${docker_compose} up -d runner_stateless

# crude wait for services
sleep 1
check_up 'cyber-dojo-runner'
check_up 'cyber-dojo-runner-stateless'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

${docker_compose} \
    run \
      image_builder_inner \
          /app/spike-curl-run.sh

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# TODO: shunit2
#
# use test/good_language
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected

# use test/good_test
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected
