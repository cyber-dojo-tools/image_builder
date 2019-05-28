#!/bin/bash

echo '-----------------------------------------'
echo 'testing language-bases'
echo 'success cases...'

# [1] no longer work because [cyber-dojo start-point create]
# requires a git-repo URL. Work in progress...
#
# Need to convert /test/languages/alpine-java into a path
# returned by a function that git-clones the real repo
# (eg java) if not available locally. The name of this
# function should reflect the intention, viz
#   alpine_language_repo_url() or
#   ubuntu_language_repo_url() or
#   alpine_testFramework_repo_url() or
#   ubuntu_testFramework_repo_url() or
# and this does the git-clone inside if need be.


test_alpine()
{
  echo '  java'
  assertBuildImage /test/languages/alpine-java
  assertAlpineImageBuilt
  assertSandboxUserPresent
  #refuteStartPointCreated [1]
  #refuteRedAmberGreen
}

test_ubuntu()
{
  echo '  perl'
  assertBuildImage /test/languages/ubuntu-perl
  assertUbuntuImageBuilt
  assertSandboxUserPresent
  #refuteStartPointCreated [1]
  #refuteRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly MY_DIR="$( cd "$( dirname "${0}" )" && pwd )"

. ${MY_DIR}/test_helpers.sh
. ${MY_DIR}/shunit2_helpers.sh
. ${MY_DIR}/shunit2
