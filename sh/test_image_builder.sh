#!/bin/bash
set -e

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

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

# good-test-framework Alpine, stateful-runner
export TRAVIS_REPO_SLUG=cyber-dojo-languages/gcc-assert
${ROOT_DIR}/run_build_image.sh ${ROOT_DIR}/test/gcc-assert

# good-test-framework Ubuntu, stateless-runner
export TRAVIS_REPO_SLUG=cyber-dojo-languages/python-pytest
${ROOT_DIR}/run_build_image.sh ${ROOT_DIR}/test/python-pytest
