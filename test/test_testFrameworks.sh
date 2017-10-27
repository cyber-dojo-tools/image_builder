#!/bin/bash

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

build_image()
{
  local src_dir=${ROOT_DIR}$1
  ${ROOT_DIR}/run_build_image.sh ${src_dir} >${stdoutF} 2>${stderrF}
  assertTrue $?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

test___success() { :; }

test_____alpine_testFramework_stateful()
{
  build_image /test/test-frameworks/alpine-gcc-assert/stateful
  cat ${stdoutF}
  assertStdoutIncludes '# check_start_point_can_be_created'
  assertStdoutIncludes "adduser -D -G cyber-dojo -h /home/flamingo -s '/bin/sh' -u 40014 flamingo"
  assertStdoutIncludes 'Welcome to Alpine Linux 3.6'
  assertStdoutIncludes '# check_start_point_src_red_green_amber_using_runner_stateful'
  assertStdoutIncludes 'red: OK'
  assertStdoutIncludes 'green: OK'
  assertStdoutIncludes 'amber: OK'
  assertNoStderr
}

test_____ubuntu_testFramework_stateless()
{
  build_image /test/test-frameworks/ubuntu-python-pytest/stateless
  cat ${stdoutF}
  assertStdoutIncludes '# check_start_point_can_be_created'
  assertStdoutIncludes "adduser --disabled-password --gecos \"\" --ingroup cyber-dojo --home /home/flamingo --uid 40014 flamingo"
  assertStdoutIncludes 'Ubuntu 17.04'
  assertStdoutIncludes '# check_start_point_src_red_green_amber_using_runner_stateless'
  assertStdoutIncludes 'red: OK'
  assertStdoutIncludes 'green: OK'
  assertStdoutIncludes 'amber: OK'
  assertNoStderr
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

. ./shunit2_helpers.sh
. ./shunit2
