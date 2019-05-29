#!/bin/bash

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly SP_DIR=`absPath "${1}"`
readonly IMAGE_NAME=${2} # will be via another script run on SP_DIR

cd "${SP_DIR}/docker" \
&& \
"${MY_DIR}/augmented_Dockerfile.sh" "${SP_DIR}/docker" \
| \
docker build --tag "${IMAGE_NAME}" -
