#!/bin/bash
set -e

# Writes an augmented Dockerfile to stdout.
# Folded into main script.

cat "${1}/Dockerfile" \
  | \
    docker run \
      --interactive \
      --rm \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      cyberdojofoundation/dockerfile_augmenter
