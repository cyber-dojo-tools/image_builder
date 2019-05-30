#!/bin/bash

echo '-----------------------------------------'
echo 'testing test-frameworks'

test_Alpine()
{
  assert_build_image $(repo_url java-junit)
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" Alpine
  assert_sandbox_user_in "${image_name}"
  assert_start_point_created
  #assert_red_amber_green
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test_Ubuntu()
{
  assert_build_image $(repo_url perl-testsimple)
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" Ubuntu
  assert_sandbox_user_in "${image_name}"
  assert_start_point_created
  #assert_red_amber_green
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test_Debian()
{
  assert_build_image $(repo_url python-pytest)
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" Debian
  assert_sandbox_user_in "${image_name}"
  assert_start_point_created
  #assert_red_amber_green
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
