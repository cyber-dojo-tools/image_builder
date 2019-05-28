#!/bin/bash

echo '-----------------------------------------'
echo 'testing test-frameworks'
echo 'success cases...'

# [1] no longer work because [cyber-dojo start-point create]
# requires a git-cloneable URL. Work in progress...

test_alpine()
{
  echo '  java-junit'
  assertBuildImage /test/test-frameworks/alpine-java-junit
  assertAlpineImageBuilt
  assertSandboxUserPresent
  #assertStartPointCreated [1]
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test_ubuntu()
{
  echo '  perl-testsimple'
  assertBuildImage /test/test-frameworks/ubuntu-perl-testsimple
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  #assertStartPointCreated [1]
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test_6_times_9_options()
{
  echo '  asm-assert'
  assertBuildImage /test/test-frameworks/asm-assert
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  #assertStartPointCreated [1]
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
