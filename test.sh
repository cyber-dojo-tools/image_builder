#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

# good-language
./run_build_image.sh ${MY_DIR}/test/haskell-7.6.3
# good-test-framework
./run_build_image.sh ${MY_DIR}/test/haskell-hunit

# TODO: shunit2
#
# use good_language
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected

# use good_test_framework
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected
