#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly IMAGE_NAME="${1}"

docker build -t "${IMAGE_NAME}" "${MY_DIR}"
