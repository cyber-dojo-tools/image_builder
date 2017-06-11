#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
export WORK_DIR=${1:-`pwd`}

docker-compose --file ${MY_DIR}/docker-compose.yml build

