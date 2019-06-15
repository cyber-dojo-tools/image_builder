#!/bin/bash
set -e

if [ "${1}" = '' ]; then
  echo 'Use: run.sh DIR'
  exit 1
fi

absPath()
{
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}

readonly START_POINT_DIR=`absPath "${1}"`

docker run \
  --env CIRCLE_API_MACHINE_USER_TOKEN \
  --interactive \
  --rm \
  --volume "${START_POINT_DIR}:/data:ro" \
    cyberdojofoundation/dependents_notifier