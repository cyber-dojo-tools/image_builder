#!/bin/bash
set -e

readonly SH_DIR="$( cd "$( dirname "${0}" )" && pwd )/sh"

${SH_DIR}/build_image_builder.sh
${SH_DIR}/test_image_builder.sh
