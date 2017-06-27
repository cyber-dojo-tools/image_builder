#!/bin/bash
set -e

./builder/build-docker-image.sh
./build.sh
./test.sh
./push.sh
