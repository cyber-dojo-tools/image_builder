#!/bin/bash
set -e

docker exec cyber-dojo-image-builder-inner /app/spike-curl-run.sh

# TODO: shunit2
#
# use test/good_language
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected

# use test/good_test
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected
