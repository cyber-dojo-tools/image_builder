#!/bin/bash

my_dir="$( cd "$( dirname "${0}" )" && pwd )"

org_name=cyberdojofoundation
tag_name=$(basename ${my_dir})
name=${org_name}/${tag_name}

repo_name=https://github.com/cyber-dojo-languages/elm-test
#repo_name=${TRAVIS_REPO_SLUG}

docker run \
  --rm \
  -it \
  --volume ${my_dir}/start_point:/start_point:ro \
  --volume ${my_dir}/docker:/docker:ro \
  ${name} ./verify.rb ${repo_name}

exit_status=$?
echo "exit_status=${exit_status}"