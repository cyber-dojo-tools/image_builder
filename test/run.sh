#!/bin/bash
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

# in order dependency...
${my_dir}/test_languages.sh
${my_dir}/test_testFrameworks.sh

# use good_language
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected

# use good_test_framework
#   copy it to /tmp
#   change something specific in /tmp
#   verify the failure is as expected
