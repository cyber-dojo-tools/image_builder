#!/bin/bash
set -e

./build.sh
./test.sh
./down.sh
./push.sh
