#!/bin/bash

echo 'dirs with /docker/ and start_point/ ==> test-frameworks default start-points'
echo 'success cases...'

test_alpine_stateful()
{
  build_image /test/test-frameworks/alpine-gcc-assert/stateful
  assertStdoutIncludes '# build_the_image'
  assertStdoutIncludes "adduser -D -G cyber-dojo -h /home/flamingo -s '/bin/sh' -u 40014 flamingo"
  assertStdoutIncludes '# check_start_point_can_be_created'
  assertStdoutIncludes '# print_image_info'
  assertStdoutIncludes 'Welcome to Alpine Linux 3.6'
  assertStdoutIncludes '# check_start_point_src_red_green_amber_using_runner_stateful'
  assertStdoutIncludes 'red: OK'
  assertStdoutIncludes 'green: OK'
  assertStdoutIncludes 'amber: OK'
  assertNoStderr
}

test_ubuntu_stateless()
{
  build_image /test/test-frameworks/ubuntu-python-pytest/stateless
  assertStdoutIncludes '# build_the_image'
  assertStdoutIncludes "adduser --disabled-password --gecos \"\" --ingroup cyber-dojo --home /home/flamingo --uid 40014 flamingo"
  assertStdoutIncludes '# check_start_point_can_be_created'
  assertStdoutIncludes '# print_image_info'
  assertStdoutIncludes 'Ubuntu 17.04'
  assertStdoutIncludes '# check_start_point_src_red_green_amber_using_runner_stateless'
  assertStdoutIncludes 'red: OK'
  assertStdoutIncludes 'green: OK'
  assertStdoutIncludes 'amber: OK'
  assertNoStderr
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
