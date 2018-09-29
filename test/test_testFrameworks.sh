#!/bin/bash

echo '-----------------------------------------'
echo 'testing test-frameworks'
echo 'success cases...'

test_alpine_stateless()
{
  echo '  java-junit'
  assertBuildImage /test/test-frameworks/alpine-java-junit/stateless
  assertAlpineImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  assertStartPointRedAmberGreenStateless
}

test_alpine_stateful()
{
  echo '  java-junit'
  assertBuildImage /test/test-frameworks/alpine-java-junit/stateful
  assertAlpineImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  assertStartPointRedAmberGreenStateful
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test_ubuntu_stateless()
{
  echo '  perl-testsimple'
  assertBuildImage /test/test-frameworks/ubuntu-perl-testsimple/stateless
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  assertStartPointRedAmberGreenStateless
}

test_ubuntu_stateful()
{
  echo '  perl-testsimple'
  assertBuildImage /test/test-frameworks/ubuntu-perl-testsimple/stateful
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  assertStartPointRedAmberGreenStateful
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test_6_times_9_options()
{
  echo '  asm-assert'
  assertBuildImage /test/test-frameworks/asm-assert
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  assertStartPointRedAmberGreenStateless
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
