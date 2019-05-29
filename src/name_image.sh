#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly START_POINT_DIR="${1}"

docker run \
  --rm \
  --interactive \
  cyberdojotools/image_namer
