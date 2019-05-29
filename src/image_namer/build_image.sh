#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker build \
  --tag cyberdojotools/image_namer \
  "${MY_DIR}" > /dev/null
