#!/bin/bash

# Spiking how to call run(...) in a runner_stateless container
# (on port 4597) from inside an image_builder container using curl.
#
# Running image_builder should be a single operation.
# At the moment it is a two-step operation as you first
# have to start the runner_stateless service which image_builder
# uses to check a test start_point. Perhaps embed docker-compose
# inside image_builder?

run() {
  local json=$1
  local port=4597
  curl \
   --silent \
   -H 'Content-Type: application/json' \
   -H 'Accept: application/json' \
   -d "${json}" \
   http://runner_stateless:${port}/run
}

run '{
  "image_name":"cyberdojofoundation/swift_swordfish",
  "kata_id":"6F4F4E4759",
  "avatar_name":"salmon",
  "max_seconds":10,
  "visible_files": {
    "cyber-dojo.sh":"pwd"
  }
}'
echo

run '{
  "image_name":"cyberdojofoundation/swift_swordfish",
  "kata_id":"6F4F4E4759",
  "avatar_name":"salmon",
  "max_seconds":10,
  "visible_files": {
    "cyber-dojo.sh":"whoami"
  }
}'
echo

#readonly NAME=cyber-dojo-runner-stateless
#docker logs ${NAME}
#docker stop ${NAME}
#docker rm   ${NAME}
