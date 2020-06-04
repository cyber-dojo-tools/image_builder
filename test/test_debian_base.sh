#!/bin/bash -Eeu

test_Debian()
{
  language_base_test Debian perl
}

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MY_DIR}/language_base_test.sh
