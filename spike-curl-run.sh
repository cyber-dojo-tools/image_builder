#!/bin/bash

# Spiking how to call run(...) in a runner_stateless container
# (on port 4597) from inside an image_builder container using curl.
#
# From Docker Toolbox terminal call this script (inside the container)
# as follows
#
#  $ ./build.sh
#  $ docker run \
#      --rm \
#      --interactive \
#      --tty \
#      --volume=/var/run/docker.sock:/var/run/docker.sock \
#      cyberdojofoundation/image_builder \
#      ./spike-curl-run.sh `docker-machine ip default`
#
# I'm using Docker Toolbox so in the curl I have to use
# (and pass in) the IP address I get from the default VM.
# This will be different on Travis (I assume).
# Travis sets the TRAVIS environment-variable so I will
# need to determine the correct IP address when on Travis.
# if [ -v TRAVIS ];
#
# Is this making things overly complicated?
# docker-compose is available in Docker Toolbox and also
# in Travis. Could use that (like web) and use Ruby library
# to do Http.

IP_ADDRESS=$1
PORT=4597
NAME=cyber-dojo-runner

docker run \
  --detach \
  --publish ${PORT}:${PORT} \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --name ${NAME} \
    cyberdojo/runner_stateless

# crude wait for Thin server in runner_stateless
sleep 1

RUN='{
  "image_name":"cyberdojofoundation/swift_swordfish",
  "kata_id":"6F4F4E4759",
  "avatar_name":"salmon",
  "max_seconds":10,
  "visible_files": {
    "cyber-dojo.sh":"pwd && whoami"
  }
}'

curl \
   -H 'Content-Type: application/json' \
   -H 'Accept: application/json' \
   -d "${RUN}" \
   http://${IP_ADDRESS}:${PORT}/run

echo
docker logs ${NAME}
docker stop ${NAME}
docker rm   ${NAME}
