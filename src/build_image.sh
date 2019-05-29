#!/bin/bash

# TODO: check $1 == "" is false
# TODO: check [ -d $1 ] is true

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly START_POINT_DIR=`absPath "${1}"`
readonly IMAGE_NAME=$("${MY_DIR}/name_image.sh" "${START_POINT_DIR}")

cd "${START_POINT_DIR}/docker" \
&& \
"${MY_DIR}/augmented_Dockerfile.sh" "${START_POINT_DIR}/docker" \
| \
docker build --tag "${IMAGE_NAME}" -
