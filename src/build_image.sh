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

readonly START_POINT_DIR=`absPath "${1}"`

readonly IMAGE_NAME=$(docker run \
  --rm \
  --interactive \
  --volume "${START_POINT_DIR}:/start_point:ro" \
  cyberdojotools/image_namer)

# - - - - - - - - - - - - - - - - - - - -

cd "${START_POINT_DIR}/docker" \
&& \
cat "./Dockerfile" \
  | \
    docker run --rm \
      --interactive \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      cyberdojotools/dockerfile_augmenter \
| \
docker build --tag "${IMAGE_NAME}" -
