#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

build_tools()
{
  "${MY_DIR}/dockerfile_augmenter/build_image.sh"
  "${MY_DIR}/image_namer/build_image.sh"
  "${MY_DIR}/dependents_notifier/build_image.sh"
}

build_tools