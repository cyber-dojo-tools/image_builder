#!/bin/bash
set -e


docker-compose run image_builder /app/spike-curl-run.sh

# TODO: shunit2
# use test/good_language
#   change a file and verify failure is as expected

# use test/good_test
#   change a file and verify failure is as expected
