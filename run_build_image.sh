#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

build_image()
{
  local repo_name=${1}

  local org_name=cyberdojofoundation
  local tag_name=$(basename ${my_dir}) # image_builder
  local name=${org_name}/${tag_name}

  if [ -d ${my_dir}/docker ]; then
    local docker_volume=--volume=${my_dir}/docker:/docker:ro
  fi
  if [ -d ${my_dir}/start_point ]; then
    local start_point_volume=--volume=${my_dir}/start_point:/start_point:ro
  fi

  docker run \
    --rm \
    -it \
    ${docker_volume} \
    ${start_point_volume} \
    ${name} ./build_image.rb ${repo_name}
}

build_image ${1}
exit_status=$?
echo "exit_status=${exit_status}"