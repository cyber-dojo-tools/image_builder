#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

"${ROOT_DIR}/src/build_tools.sh"
"${ROOT_DIR}/test/run.sh"
