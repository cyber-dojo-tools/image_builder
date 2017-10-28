#!/bin/bash

echo 'dirs with /docker/ and start_point/ ==> test-frameworks default start-points'
echo 'success cases...'

test_alpine_stateful()
{
  echo '  gcc-assert'
  assertBuildImage /test/test-frameworks/alpine-gcc-assert/stateful
  assertAlpineImageBuilt
  assertStartPointCreated
  assertStartPointRedAmberGreenStateful
}

test_alpine_stateless()
{
  echo '  gcc-assert'
  assertBuildImage /test/test-frameworks/alpine-gcc-assert/stateless
  assertAlpineImageBuilt
  assertStartPointCreated
  assertStartPointRedAmberGreenStateless
}

test_ubuntu_stateless()
{
  echo '  python-pytest'
  assertBuildImage /test/test-frameworks/ubuntu-python-pytest/stateless
  assertUbuntuImageBuilt
  assertStartPointCreated
  assertStartPointRedAmberGreenStateless
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
