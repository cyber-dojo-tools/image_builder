#!/bin/bash
#set -e
set -x

# Runs image-builder on source living in WORK_DIR which
# can be passed as $1 and default to the current work directory.

# TODO: Simpler and cleaner toput docker-compose inside image_builder
# (like commander) which has three services, builder,runner,runner_stateless

export WORK_DIR=${1:-`pwd`}

if [ ! -d ${WORK_DIR} ]; then
  echo "FAILED: ${WORK_DIR} dir does not exist"
  exit 1
fi

readonly URL=https://raw.githubusercontent.com/cyber-dojo-languages/image_builder/master

readonly COMPOSE_YML=docker-compose.yml
if [ ! -f ${WORK_DIR}/${COMPOSE_YML} ]; then
  curl ${URL}/${COMPOSE_YML} > ${WORK_DIR}/${COMPOSE_YML}
fi

readonly UP_SCRIPT=up.sh
if [ ! -f ${WORK_DIR}/${UP_SCRIPT} ]; then
  curl ${URL}/${UP_SCRIPT} > ${WORK_DIR}/${UP_SCRIPT}
  chmod +x ${WORK_DIR}/${UP_SCRIPT}
fi

docker pull cyberdojofoundation/image_builder
${WORK_DIR}/up.sh

#--env GITHUB_TOKEN=${GITHUB_TOKEN} \
#--env=DOCKER_USERNAME=${DOCKER_USERNAME} \
#--env=DOCKER_PASSWORD=${DOCKER_PASSWORD} \
#--env=WORK_DIR=${WORK_DIR} \

echo "about to docker exec"
echo "DOCKER_USERNAME=:${DOCKER_USERNAME}:"
echo "WORK_DIR=:${WORK_DIR}:"

docker --version
docker exec --help

# [docker exec] on Travis does not have --env option
docker exec \
  --interactive \
  --tty \
  cyber-dojo-image-builder \
    bash -c \
    "export DOCKER_USERNAME=${DOCKER_USERNAME} && \
     export DOCKER_PASSWORD=${DOCKER_PASSWORD} && \
     export WORK_DIR=${WORK_DIR} && \
     /app/build_image.rb"
