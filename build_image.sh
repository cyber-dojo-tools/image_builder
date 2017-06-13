#!/bin/bash
set -e

# This is the main entry-point for the image_builder
# docker-image which includes docker-compose inside it.

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

echo "inside image_builder2/build_image.sh"
echo "DOCKER_USERNAME=:${DOCKER_USERNAME}:"
echo "DOCKER_PASSWORD=:${DOCKER_PASSWORD}:"
echo "SRC_DIR=:${SRC_DIR}:"

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
${docker_compose} up -d image_builder_inner

sleep 1
check_up 'cyber-dojo-runner'
check_up 'cyber-dojo-runner-stateless'

#TODO: ${docker_compose} -e KEY=VAL run image_builder
#with KEY=VAL for DOCKER_USERNAME, DOCKER_PASSWORD, SRC_DIR

check_up 'cyber-dojo-image-builder-inner'

#TODO: add GITHUB_TOKEN

docker exec \
  --interactive \
  --tty \
  cyber-dojo-image-builder-inner \
    bash -c \
    "env \
       DOCKER_USERNAME=${DOCKER_USERNAME} \
       DOCKER_PASSWORD=${DOCKER_PASSWORD} \
       SRC_DIR=${SRC_DIR} \
         /app/build_image.rb"

${docker_compose} down
sleep 1
docker volume rm ${NAME}
