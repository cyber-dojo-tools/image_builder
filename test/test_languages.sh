#!/bin/bash

echo 'dirs with /docker/ only ==> languages'
echo 'success cases...'

test_alpine()
{
  echo '  gcc'
  assertBuildImage /test/languages/alpine-gcc
  echo '1'
  assertAlpineImageBuilt
  echo '2'
  refuteStartPointCreated
  echo '3'
  refuteRedAmberGreen
  echo '4'
}

test_ubuntu()
{
  echo '  python'
  assertBuildImage /test/languages/ubuntu-python
  assertUbuntuImageBuilt
  refuteStartPointCreated
  refuteRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
