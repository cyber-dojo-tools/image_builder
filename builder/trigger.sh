#!/bin/sh

# https://docs.travis-ci.com/user/triggering-builds
# https://developer.travis-ci.org/authentication
# https://developer.travis-ci.org/resource/requests#create

TOKEN=$1
NAME=$2   # eg 'cyber-dojo-languages'
TAG=$3    # eg 'java-junit'

body='{
"request": {
"branch":"master"
}}'

curl -s -X POST \
   -H "Content-Type: application/json" \
   -H "Accept: application/json" \
   -H "Travis-API-Version: 3" \
   -H "Authorization: token ${TOKEN}" \
   -d "${body}" \
   https://api.travis-ci.org/repo/${NAME}%2F${TAG}/requests

readonly exit_status=$?
echo ''
echo "curl exit_status=${exit_status}"
exit ${exit_status}
