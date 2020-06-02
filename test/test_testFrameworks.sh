#!/bin/bash -Eeu

echo '-----------------------------------------'
echo 'testing test-frameworks'

language_testFramework_test()
{
  local os="${1}"
  local name="${2}"

  assert_build_image $(repo_url "${name}")
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" "${os}"
  assert_sandbox_user_in "${image_name}"
  #assert_start_point_created
  #refute_pushing_to_dockerhub "${image_name}"
  #refute_notifying_dependents
}

test_Alpine() { language_testFramework_test Alpine ruby-testunit    ; }
test_Debian() { language_testFramework_test Debian perl-testsimple ; }
test_Ubuntu() { language_testFramework_test Ubuntu haskell-hunit   ; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

XXXXX_test_6_times_9_options()
{
  echo '  asm-assert'
  assertBuildImage $(repo_url asm-assert)
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  assertStartPointCreated
  #assertStartPointRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
