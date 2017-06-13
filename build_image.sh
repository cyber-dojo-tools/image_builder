#!/bin/bash
set -e

# This is the main entry-point for the image_builder
# docker-image which includes docker-compose inside it.

check_up()
{
  #TODO: loop till $1 is up or max_seconds has elapsed
  #      and remove sleep from below.
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

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly NAME=language

docker volume create --name=${NAME}

readonly cid=$(docker create \
  --interactive \
  --user=root \
  --volume=${NAME}:/repo \
    cyberdojo/runner \
      sh)

docker cp ${SRC_DIR}/. ${cid}:/repo
docker rm -f ${cid}

readonly docker_compose="docker-compose --file ${MY_DIR}/docker-compose.yml"

${docker_compose} up -d runner
${docker_compose} up -d runner_stateless

sleep 1
check_up 'cyber-dojo-runner'
check_up 'cyber-dojo-runner-stateless'

${docker_compose} \
    run \
      -e DOCKER_USERNAME=${DOCKER_USERNAME} \
      -e DOCKER_PASSWORD=${DOCKER_PASSWORD} \
      -e GITHUB_TOKEN=${GITHUB_TOKEN} \
      -e SRC_DIR=${SRC_DIR} \
        image_builder_inner \
          /app/build_image.rb

${docker_compose} down
sleep 2
docker volume rm ${NAME}
