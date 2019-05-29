#!/bin/bash

if [ "${1}" = '' ]; then
  echo 'Use: notify_dependents.sh DIR'
  exit 1
fi

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

readonly START_POINT_DIR=`absPath "${1}"`

docker run \
  --env DOCKER_USERNAME \
  --env DOCKER_PASSWORD \
  --env GITHUB_TOKEN \
  --env TRAVIS \
  --env TRAVIS_EVENT_TYPE \
  --env TRAVIS_REPO_SLUG \
  --rm \
  --volume "${START_POINT_DIR}:/data:ro" \
    cyberdojo/dependents_notifier
