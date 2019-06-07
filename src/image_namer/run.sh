#!/bin/bash
set -e

# Writes the name of the docker-image to stdout.
# Folded into main script.

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

readonly START_POINT_DIR=`absPath "${1}"`

docker run \
  --interactive \
  --rm \
  --volume "${START_POINT_DIR}:/data:ro" \
  cyberdojotools/image_namer
