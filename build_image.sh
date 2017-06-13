#!/bin/bash
set -e

check_up()
{
  set +e
  local s=$(docker ps --filter status=running --format '{{.Names}}' | grep ^${1}$)
  set -e
  if [ "${s}" != "${1}" ]; then
    echo
    echo "${1} exited"
    docker logs ${1}
    exit 1
  fi
}

echo "inside image_builder2/build_image.sh"
echo "DOCKER_USERNAME=:${DOCKER_USERNAME}:"
echo "DOCKER_PASSWORD=:${DOCKER_PASSWORD}:"
echo "WORK_DIR=:${WORK_DIR}:"

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly NAME=language

docker volume create --name=${NAME}

readonly cid=$(docker create \
  --interactive \
  --user=root \
  --volume=${NAME}:/repo \
    cyberdojo/runner \
      sh)

docker cp ${WORK_DIR}/. ${cid}:/repo

#docker stop ${cid}
#docker rm --volumes ${cid}

#TODO: docker-compose            up runner
#TODO: docker-compose            up runner-stateless
#TODO: docker-compose -e KEY=VAL run builder

docker-compose --file ${MY_DIR}/docker-compose2.yml up -d

sleep 1
check_up 'cyber-dojo-image-builder'
check_up 'cyber-dojo-runner'
check_up 'cyber-dojo-runner-stateless'

#TODO: GITHUB_TOKEN

docker exec \
  --interactive \
  --tty \
  cyber-dojo-image-builder \
    bash -c \
    "env \
       DOCKER_USERNAME=${DOCKER_USERNAME} \
       DOCKER_PASSWORD=${DOCKER_PASSWORD} \
       WORK_DIR=${WORK_DIR} \
         /app/build_image.rb"

