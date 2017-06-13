#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly NAME=language

docker-compose --file ${MY_DIR}/docker-compose.yml down
docker volume rm ${NAME}