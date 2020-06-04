#!/bin/bash -Eeu

readonly my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# these
${my_dir}/test_alpine_base.sh
${my_dir}/test_debian_base.sh
${my_dir}/test_ubuntu_base.sh

# before these
${my_dir}/test_alpine_testFramework.sh
${my_dir}/test_debian_testFramework.sh
${my_dir}/test_ubuntu_testFramework.sh
