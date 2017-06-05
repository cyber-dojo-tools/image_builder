#!/bin/bash -x

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
}

# ls -al /var/run
# lrwxrwxrwx 1 root root 4 Nov 30  2016 /var/run -> /run

# ls -al /run
# srw-rw----  1 root       docker        0 Jun  5 20:58 docker.sock

#find / -name "docker.dock"

build_image ${1}
exit_status=$?
echo "exit_status=${exit_status}"