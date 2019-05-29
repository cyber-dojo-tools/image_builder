#!/bin/bash

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

docker build \
  --tag cyberdojo/dockerfile_augmenter \
  "${MY_DIR}"
