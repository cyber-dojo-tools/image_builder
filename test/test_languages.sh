#!/bin/bash

echo '-----------------------------------------'
echo 'testing language-bases'

test_alpine()
{
  echo '  java'
  assertBuildImage $(repo_url java)
  assertAlpineImageBuilt
  assertSandboxUserPresent
  refuteStartPointCreated
  #refuteRedAmberGreen
}

test_ubuntu()
{
  echo '  perl'
  assertBuildImage $(repo_url perl)
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  refuteStartPointCreated
  #refuteRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
