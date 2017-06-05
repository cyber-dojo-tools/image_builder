#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

build_image()
{
  local repo_name=${1}

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
    cyberdojofoundation/image_builder \
      ./build_image.rb ${repo_name}
}

build_image ${1}
exit_status=$?
echo "exit_status=${exit_status}"