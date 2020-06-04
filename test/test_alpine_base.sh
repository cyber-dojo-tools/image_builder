#!/bin/bash -Eeu

test_Alpine()
{
  language_base_test Alpine ruby
}

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${MY_DIR}/language_base_test.sh
