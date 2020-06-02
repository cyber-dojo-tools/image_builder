#!/bin/bash -Eeu

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# in order dependency...
${my_dir}/test_languages.sh
${my_dir}/test_testFrameworks.sh
