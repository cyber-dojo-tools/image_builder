#!/bin/bash -Eeu

test_Ubuntu()
{
  language_testFramework_test Ubuntu haskell-hunit
}

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MY_DIR}/language_test_framework_test.sh
