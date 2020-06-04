#!/bin/bash -Eeu

test_Alpine_testFramework()
{
  language_testFramework_test Alpine ruby-testunit
}

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MY_DIR}/language_test_framework_test.sh
