#!/bin/bash

exit_fail()
{
  echo "FAILED:${1}"
  exit 1
}

work_dir=$1

if [ -z "${work_dir}" ]; then
  exit_fail "you must pass the working-dir as an arg"
fi
if [ ! -d "${work_dir}" ]; then
  exit_fail "${work_dir} dir does not exist"
fi
if [ -z "${REPO_URL}" ]; then
  exit_fail "REPO_URL environment-variable not set"
fi

docker run \
    --rm \
    -it \
    --env DOCKER_USERNAME=${DOCKER_USERNAME} \
    --env DOCKER_PASSWORD=${DOCKER_PASSWORD} \
    --env REPO_URL=${REPO_URL} \
    --volume=/var/run/docker.sock:/var/run/docker.sock \
    --volume=${work_dir}:/language:ro \
    cyberdojofoundation/image_builder \
      ./build_image.rb
