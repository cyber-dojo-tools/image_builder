#!/bin/bash

echo '-----------------------------------------'
echo 'testing language-bases'
echo 'success cases...'

test_alpine()
{
  echo '  java'
  assertBuildImage /test/languages/alpine-java
  assertAlpineImageBuilt
  assertAlpineAvatarUsersAdded
  refuteStartPointCreated
  refuteRedAmberGreen
}

test_ubuntu()
{
  echo '  perl'
  assertBuildImage /test/languages/ubuntu-perl
  assertUbuntuImageBuilt
  assertUbuntuAvatarUsersAdded
  refuteStartPointCreated
  refuteRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
