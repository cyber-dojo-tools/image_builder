#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

ORG_NAME=cyberdojofoundation
TAG_NAME=$(basename ${my_dir})
docker build --tag ${ORG_NAME}/${TAG_NAME} ${my_dir}
