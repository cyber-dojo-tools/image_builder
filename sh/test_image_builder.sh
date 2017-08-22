#!/bin/bash
set -e

echo "~~~~~~~~"
echo "sh/INSIDE test_image_builder.sh"
echo "~~~~~~~~"

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

# good-test-framework
export TRAVIS_REPO_SLUG=cyber-dojo-languages/gcc-assert
${ROOT_DIR}/run_build_image.sh ${ROOT_DIR}/test/gcc-assert

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
