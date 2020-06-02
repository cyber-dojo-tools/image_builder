#!/bin/bash -Eeu

echo '-----------------------------------------'
echo 'testing language-bases'

language_base_test()
{
  local os="${1}"
  local name="${2}"

  assert_build_image $(repo_url "${name}")
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" "${os}"
  assert_sandbox_user_in "${image_name}"
  #refute_start_point_created
  #refute_red_amber_green
  #refute_pushing_to_dockerhub "${image_name}"
  #refute_notifying_dependents
}

test_Alpine() { language_base_test Alpine ruby    ; }
test_Debian() { language_base_test Debian perl    ; }
test_Ubuntu() { language_base_test Ubuntu haskell ; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
