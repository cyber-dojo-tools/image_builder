#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

ORG_NAME=cyberdojofoundation
TAG_NAME=$(basename ${TRAVIS_REPO_SLUG})
docker build --tag ${ORG_NAME}/${TAG_NAME} ${my_dir}
