#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

build_image()
{
  local src_dir=${ROOT_DIR}$1
  ${ROOT_DIR}/run_build_image.sh ${src_dir} >${stdoutF} 2>${stderrF}
  assertTrue $?
}
