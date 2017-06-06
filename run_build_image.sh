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
  if [ -z "${work_dir}" ]; then
    exit_fail "you must pass the dir docker/ lives is as an arg"
  fi
  if [ ! -d "${work_dir}" ]; then
    exit_fail "${work_dir}/ does not exist"
  fi
  if [ ! -d "${work_dir}/docker" ]; then
    exit_fail "${work_dir}/docker/ does not exist"
  fi
  if [ -z "${DOCKER_USERNAME}" ]; then
    exit_fail "DOCKER_USERNAME environment-variable not set"
  fi
  if [ -z "${DOCKER_PASSWORD}" ]; then
    exit_fail "DOCKER_PASSWORD environment-variable not set"
  fi
  if [ -z "${REPO_URL}" ]; then
    exit_fail "REPO_URL environment-variable not set"
  fi

  # docker.sock is needed is you are running on a local Docker Toolbox
  local volume_docker_socket=--volume=/var/run/docker.sock:/var/run/docker.sock
  local volume_docker_dir=--volume=${work_dir}/docker:/docker:ro
  if [ -d ${work_dir}/start_point ]; then
    local volume_start_point_dir=--volume=${work_dir}/start_point:/start_point:ro
  fi
  if [ -d ${work_dir}/outputs ]; then
    local volume_outputs_dir=--volume=${work_dir}/outputs:/outputs:ro
  fi

  # TODO:volume for traffic_lights
  # TODO:version?

  docker run \
    --rm \
    -it \
    --env DOCKER_USERNAME=${DOCKER_USERNAME} \
    --env DOCKER_PASSWORD=${DOCKER_PASSWORD} \
    --env REPO_URL=${REPO_URL} \
    ${volume_docker_socket} \
    ${volume_docker_dir} \
    ${volume_start_point_dir} \
    ${volume_outputs_dir} \
    cyberdojofoundation/image_builder \
      ./build_image.rb
}

build_image $*
