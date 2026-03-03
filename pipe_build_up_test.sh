#!/usr/bin/env bash
set -Eeu

readonly ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${ROOT_DIR}/test/run.sh"
