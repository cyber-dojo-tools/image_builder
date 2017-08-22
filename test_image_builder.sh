#!/bin/bash
set -e

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

# good-test-framework
export TRAVIS_REPO_SLUG=cyber-dojo-languages/gcc-assert
./run_build_image.sh ${MY_DIR}/test/gcc-assert

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
