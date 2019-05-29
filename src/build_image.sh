#!/bin/bash

# TODO: check $1 == "" is false
# TODO: check [ -d $1 ] is true

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

# TODO: build images here for now.
# Will need to be pushed to dockerhub in CI pipe.
# Put them into their own repos?
"${MY_DIR}/dockerfile_augmenter/build_image.sh"
"${MY_DIR}/image_namer/build_image.sh"

# - - - - - - - - - - - - - - - - - - - -

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

# TODO: 2 helper scripts will need to folded into
# the main run_build_image.sh script which is curl'd
# by each cyber-dojo-languages repo's CI script.

readonly START_POINT_DIR=`absPath "${1}"`
readonly IMAGE_NAME=$("${MY_DIR}/name_image.sh" "${START_POINT_DIR}")

cd "${START_POINT_DIR}/docker" \
&& \
"${MY_DIR}/augmented_Dockerfile.sh" "${START_POINT_DIR}/docker" \
| \
docker build --tag "${IMAGE_NAME}" -
