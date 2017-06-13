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

docker-compose --file ${MY_DIR}/docker-compose.yml up -d
# crude wait for services
sleep 1
check_up 'cyber-dojo-image-builder-inner'
check_up 'cyber-dojo-runner'
check_up 'cyber-dojo-runner-stateless'
