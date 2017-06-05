#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

build_image()
{
  local repo_name=${1}
  local docker_socket=/var/run/docker.sock:/var/run/docker.sock
  if [ -d ${my_dir}/docker ]; then
    local docker_src=${my_dir}/docker:/docker:ro
  fi
  if [ -d ${my_dir}/start_point ]; then
    local start_point=${my_dir}/start_point:/start_point:ro
  fi
  docker run \
    --rm \
    -it \
    --volume=${docker_socket} \
    --volume=${docker_src} \
    --volume=${start_point} \
    cyberdojofoundation/image_builder \
      ./build_image.rb ${repo_name}
}

build_image ${1}
exit_status=$?
echo "exit_status=${exit_status}"