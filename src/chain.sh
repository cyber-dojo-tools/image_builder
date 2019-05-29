#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

"${MY_DIR}/dockerfile_augmenter/build_image.sh"
"${MY_DIR}/image_namer/build_image.sh"
"${MY_DIR}/build_image.sh" "${1}"
