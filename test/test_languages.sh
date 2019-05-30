#!/bin/bash

echo '-----------------------------------------'
echo 'testing language-bases'

test_Alpine()
{
  assert_build_image $(repo_url java)
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" Alpine
  assert_sandbox_user_in "${image_name}"
  refute_start_point_created
  #refute_red_amber_green
}

test_Ubuntu()
{
  assert_build_image $(repo_url perl)
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" Ubuntu
  assert_sandbox_user_in "${image_name}"
  refute_start_point_created
  #refute_red_amber_green
}

test_Debian()
{
  assert_build_image $(repo_url python)
  local image_name=$(image_name_from_stdout)
  assert_image_OS "${image_name}" Debian
  assert_sandbox_user_in "${image_name}"
  refute_start_point_created
  #refute_red_amber_green
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
