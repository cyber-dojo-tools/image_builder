#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

build_tools() # here for now
{
  "${MY_DIR}/dockerfile_augmenter/build_image.sh"
  "${MY_DIR}/image_namer/build_image.sh"
  "${MY_DIR}/dependents_notifier/build_image.sh"
}

# - - - - - - - - - - - - - - - - - - - -

readonly CONTEXT_DIR=$(mktemp -d)

remove_context_dir()
{
  rm -rf "${CONTEXT_DIR}" > /dev/null
}

trap remove_context_dir EXIT

# - - - - - - - - - - - - - - - - - - - -

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

# - - - - - - - - - - - - - - - - - -

build_image()
{
  local START_POINT_DIR=`absPath "${1}"`

  # Find out the name of the docker-image.
  local IMAGE_NAME=$(docker run \
    --rm \
    --interactive \
    --volume "${START_POINT_DIR}:/data:ro" \
    cyberdojo/image_namer)

  # move the docker/ dir into a new temporary context-dir
  # so we can overwrite its Dockerfile
  cp -R "${START_POINT_DIR}/docker/" "${CONTEXT_DIR}"

  # Overwrite the Dockerfile with one containing
  # extra commands to fulfil the runner's requirements.
  cat "${START_POINT_DIR}/docker/Dockerfile" \
    | \
      docker run --rm \
        --interactive \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        cyberdojo/dockerfile_augmenter \
    > \
      "${CONTEXT_DIR}/Dockerfile"

  # Write new Dockerfile to stdout in case of debugging
  echo '# ~~~~~~~~~~~~~~~~~~~~~~~~~'
  cat "${CONTEXT_DIR}/Dockerfile"
  echo '# ~~~~~~~~~~~~~~~~~~~~~~~~~'

  # Build the docker-image
  docker build \
    --tag "${IMAGE_NAME}" \
    "${CONTEXT_DIR}"
}

# - - - - - - - - - - - - - - - - - -

if [ "${1}" = '' ]; then
  echo 'Use: build_image.sh DIR'
  exit 1
fi

if [ ! -d "${1}" ]; then
  echo 'Use: build_image.sh DIR'
  echo 'DIR does not exist'
  exit 1
fi

build_tools
build_image "${1}"
