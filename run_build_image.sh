#!/bin/bash

exit_fail()
{
  echo "FAILED:${1}"
  exit 1
}

build_image()
{
  local work_dir=$1
  shift

  if [ ! -d ${work_dir}/docker ]; then
    exit_fail "there is no docker/ directory"
  fi

  # docker.sock is needed is you are running on a local Docker Toolbox
  local volume_docker_socket=--volume=/var/run/docker.sock:/var/run/docker.sock
  local volume_docker_src=--volume=${work_dir}/docker:/docker:ro
  if [ -d ${work_dir}/start_point ]; then
    local volume_start_point=--volume=${work_dir}/start_point:/start_point:ro
  fi

  docker run \
    --rm \
    -it \
    ${volume_docker_socket} \
    ${volume_docker_src} \
    ${volume_start_point} \
    cyberdojofoundation/image_builder \
      ./build_image.rb $*
}

build_image $*
