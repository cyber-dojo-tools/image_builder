#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker-compose --file ${MY_DIR}/docker-compose.yml up -d

# crude wait for Thin server in runner_stateless
sleep 2