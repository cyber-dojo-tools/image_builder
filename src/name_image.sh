#!/bin/bash

# Used by build_image.sh, writes the name of the docker-image to stdout

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly START_POINT_DIR="${1}"

docker run \
  --rm \
  --interactive \
  --volume "${START_POINT_DIR}:/start_point:ro" \
  cyberdojotools/image_namer
