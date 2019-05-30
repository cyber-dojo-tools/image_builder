#!/bin/bash

echo '-----------------------------------------'
echo 'testing test-frameworks'

X_test_alpine()
{
  echo '  java-junit'
  assertBuildImage $(repo_url java-junit)
  assertAlpineImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated [1]
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

X_test_ubuntu()
{
  echo '  perl-testsimple'
  assertBuildImage $(repo_url perl-testsimple)
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

X_test_6_times_9_options()
{
  echo '  asm-assert'
  assertBuildImage $(repo_url asm-assert)
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
