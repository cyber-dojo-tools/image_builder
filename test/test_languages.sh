#!/bin/bash

echo '-----------------------------------------'
echo 'testing language-bases'

image_name_from_stdout()
{
  local stdout=$(cat "${stdoutF}")
  [[ "${stdout}" =~ Successfully[[:space:]]created[[:space:]]docker-image[[:space:]]([^[:space:]]+) ]] && echo ${BASH_REMATCH[1]}
}

assertImageOS()
{
  local image_name="${1}"
  local os="${2}"
  local etc_issue=$(docker run --rm -i "${image_name}" bash -c 'cat /etc/issue')
  local diagnostic="${image_name} is NOT based on ${os}...(${etc_issue})"
  grep --silent "${os}" <<< "${etc_issue}"
  assertTrue "${diagnostic}" $?
  echo -e "\t-is based on ${os}"
}

assertSandboxUserIn()
{
  local image_name="${1}"
  local sandbox_user='sandbox:x:41966:51966:'
  local etc_passwd=$(docker run --rm -i "${image_name}" bash -c 'cat /etc/passwd')
  local diagnostic="${image_name} does NOT have a sandbox user...${etc_passwd}"
  grep --silent "${sandbox_user}" <<< "${etc_passwd}"
  assertTrue "${diagnostic}" $?
  echo -e "\t-has a sandbox user"
}

test_Alpine()
{
  assertBuildImage $(repo_url java)
  local image_name=$(image_name_from_stdout)
  echo -e "\timage-name==${image_name}"
  assertImageOS "${image_name}" Alpine
  assertSandboxUserIn "${image_name}"
  #refuteStartPointCreated
  #refuteRedAmberGreen
}

X_test_Ubuntu()
{
  assertBuildImage $(repo_url perl)
  local image_name=$(image_name_from_stdout)
  echo -e "\t${image_name}"
  assertImageOS "${image_name}" Ubuntu
  assertSandboxUserIn "${image_name}"
  #refuteStartPointCreated
  #refuteRedAmberGreen
}

X_test_Debian()
{
  assertBuildImage $(repo_url python)
  local image_name=$(image_name_from_stdout)
  echo -e "\t${image_name}"
  assertImageOS "${image_name}" Debian
  assertSandboxUserIn "${image_name}"
  #refuteStartPointCreated
  #refuteRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
