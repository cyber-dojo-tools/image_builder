#/bin/sh
set -e

# https://circleci.com/docs/2.0/api-job-trigger/
#
# NB:1 CIRCLE_API_USER_TOKEN is a personal API token.
# https://circleci.com/docs/2.0/managing-api-tokens/#creating-a-personal-api-token
# Remember to copy the token so you can add it as an env-var at the project level.
#
# NB:2
# <quote>
# Jobs that are triggered via the API do **not** have access
# to environment variables created for a CircleCI Context
# </quote>
# So require env-vars cannot be specified once at the org level in the context.
# Which is a shame. Instead they have to be repeatedly defined for each project.
# The is not so bad since one project can Import (env) Variables
# from another project. See
# https://circleci.com/docs/2.0/env-vars/#setting-an-environment-variable-in-a-project

VCS_TYPE=github
ORG=cyber-dojo-languages
PROJECT="${1}" # eg 'java-junit'
BRANCH=master

curl -u ${CIRCLE_API_USER_TOKEN}: \
     -d build_parameters[CIRCLE_JOB]=build-publish-trigger \
     https://circleci.com/api/v1.1/project/${VCS_TYPE}/${ORG}/${PROJECT}/tree/${BRANCH}
