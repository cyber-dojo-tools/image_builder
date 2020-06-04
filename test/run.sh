#!/bin/bash -Eeu

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -x docker ]; then
  curl -sSL https://get.docker.com/ | sh
fi
# in order dependency...
${my_dir}/test_languages.sh
${my_dir}/test_testFrameworks.sh
