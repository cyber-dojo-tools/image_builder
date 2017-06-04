#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

org_name=cyberdojofoundation
tag_name=$(basename ${my_dir})
name=${org_name}/${tag_name}

docker build --tag ${name} ${my_dir}
