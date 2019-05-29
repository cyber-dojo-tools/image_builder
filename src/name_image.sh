#!/bin/bash

# Used by build_image.sh, writes the name of the docker-image to stdout
# Folded into main script.

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

readonly START_POINT_DIR=`absPath "${1}"`

docker run \
  --rm \
  --interactive \
  --volume "${START_POINT_DIR}:/start_point:ro" \
  cyberdojotools/image_namer
