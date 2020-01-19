#!/bin/bash -Eeu

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && pwd )"

"${ROOT_DIR}/test/run.sh"
