#!/bin/bash -Eeu

test_Debian_testFramework()
{
  language_testFramework_test Debian perl-testsimple
}

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MY_DIR}/language_test_framework_test.sh
