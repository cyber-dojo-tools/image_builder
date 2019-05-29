#!/bin/bash

# Writes an augmented Dockerfile to stdout.
# Folded into main script.

cat "${1}/Dockerfile" \
  | \
    docker run --rm \
      --interactive \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      cyberdojotools/dockerfile_augmenter
