#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

export WORK_DIR=${1:-`pwd`}

if [ ! -d "${WORK_DIR}" ]; then
  echo "FAILED: ${WORK_DIR} dir does not exist"
  exit 1
fi

${MY_DIR}/build.sh
${MY_DIR}/up.sh
docker exec -it cyber-dojo-image-builder /app/build_image.rb
