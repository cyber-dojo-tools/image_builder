#/bin/sh
set -e

# https://circleci.com/docs/2.0/api-job-trigger/
#
# NB:1
# <quote>
# Jobs that are triggered via the API do **not** have access
# to environment variables created for a CircleCI Context
# </quote>
# Instead they have to be repeatedly defined for each project.
# The is not so bad since one project can Import (env) Variables
# from another project. See
# https://circleci.com/docs/2.0/env-vars/#setting-an-environment-variable-in-a-project
#
# NB:2
# CIRCLE_API_MACHINE_USER_TOKEN is a personal API token.
# https://circleci.com/docs/2.0/managing-api-tokens/#creating-a-personal-api-token
# This env-var has to be added to each project (see NB:1).
#
# NB:3
# Triggering a CircleCI workflow via a CircleCI API POST request
# means the latest git-commit sha (CIRCLE_SHA1) is _NOT_ unique.
# (Aside, CIRCLE_WORKFLOW_ID is). I normally use the git commit sha
# to ensure a unique image tag and thus image immutability.
# However, in this case, images created for the cyber-dojo-languages
# org (eg java-junit) always use the :latest tag anyway.

VCS_TYPE=github
ORG=cyber-dojo-languages
PROJECT="${1}" # eg 'java-junit'
BRANCH=master

curl --user ${CIRCLE_API_MACHINE_USER_TOKEN}: \
     --data build_parameters[CIRCLE_JOB]=build-publish-trigger \
     https://circleci.com/api/v1.1/project/${VCS_TYPE}/${ORG}/${PROJECT}/tree/${BRANCH}
