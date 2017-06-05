#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

build_image()
{
  local repo_name=${1}
  local volume_docker_socket=--volume=/var/run/docker.sock:/var/run/docker.sock
  if [ -d ${my_dir}/docker ]; then
    local volume_docker_src=--volume=${my_dir}/docker:/docker:ro
  fi
  if [ -d ${my_dir}/start_point ]; then
    local volume_start_point=--volume=${my_dir}/start_point:/start_point:ro
  fi

  docker run \
    --rm \
    -it \
    ${volume_docker_socket} \
    ${volume_docker_src} \
    ${volume_start_point} \
    cyberdojofoundation/image_builder \
      ./build_image.rb ${repo_name}

  docker images
}

build_image ${1}
exit_status=$?
echo "exit_status=${exit_status}"