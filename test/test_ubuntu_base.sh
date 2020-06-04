#!/bin/bash -Eeu

test_Ubuntu()
{
  language_base_test Ubuntu haskell
}

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MY_DIR}/language_base_test.sh
