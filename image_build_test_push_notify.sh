#!/bin/bash -Ee

# - - - - - - - - - - - - - - - - - - - - - - -
# Curl'd and run in CircleCI scripts of all repos
# of the cyber-dojo-languages github organization.
#
# Note: TMP_DIR is off ~ and not /tmp because if we are
# not running on native Linux (eg on Docker-Toolbox on a Mac)
# then we need the TMP_DIR in a location which is visible
# (as a default volume-mount) inside the VM being used.
# - - - - - - - - - - - - - - - - - - - - - - -

readonly TMP_DIR=$(mktemp -d ~/tmp-cyber-dojo.image_builder.XXXXXX)
remove_tmp_dir() { rm -rf "${TMP_DIR}" > /dev/null; }
trap_handler() { remove_tmp_dir; }
trap trap_handler EXIT

# - - - - - - - - - - - - - - - - - - - - - - -
show_use_short()
{
  local -r my_name=$(basename ${BASH_SOURCE[0]})
  echo "Use: ${my_name} [GIT_REPO_DIR|-h|--help]"
  echo ''
  echo '  GIT_REPO_DIR defaults to ${PWD}.'
  echo '  GIT_REPO_DIR must hold a git repo.'
  echo '  GIT_REPO_DIR/docker/Dockerfile.base must exist.'
  echo ''
}

# - - - - - - - - - - - - - - - - - - - - - - -
show_use_long()
{
  show_use_short
  cat <<- EOF
  Step 1.
  Creates \${GIT_REPO_DIR}/docker/Dockerfile from \${GIT_REPO_DIR}/docker/Dockerfile.base
    augmented to fulfil the runner service's requirements.

  Step 2.
  Uses \${GIT_REPO_DIR}/docker/Dockerfile to build a docker image.
  The name of the docker-image is:
    the 'image_name' property of \${GIT_REPO_DIR}/start_point/manifest.json, if it exists,
    otherwise of \${GIT_REPO_DIR}/docker/image_name.json.
  Embeds an env-var of the git commit sha inside this image:
    SHA=\$(cd \${GIT_REPO_DIR} && git rev-parse HEAD)

  Step 3.
  If running on the CI/CD pipeine:
    *) Tags the docker-image with TAG=\${SHA:0:7}
    *) Pushes the docker-image (tagged to \${TAG}) to dockerhub
    *) Pushes the docker-image (tagged to latest) to dockerhub

EOF
}

# - - - - - - - - - - - - - - - - - - - - - - -
exit_zero_if_show_help()
{
  if [ "${1}" == '-h' ] || [ "${1}" == '--help' ]; then
    show_use_long
    exit 0
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
exit_non_zero_unless_good_GIT_REPO_DIR()
{
  local -r git_repo_dir="${1:-${PWD}}"
  if [ ! -d "${git_repo_dir}" ]; then
    show_use_short
    stderr "ERROR: ${git_repo_dir} does not exist."
    exit 42
  fi
  if [ ! -f "${git_repo_dir}/docker/Dockerfile.base" ]; then
    show_use_short
    stderr "ERROR: ${git_repo_dir}/docker/Dockerfile.base does not exist."
    exit 42
  fi
  if [ ! $(cd ${git_repo_dir} && git rev-parse HEAD 2> /dev/null) ]; then
    show_use_short
    stderr "ERROR: ${git_repo_dir} is not in a git repo."
    exit 42
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
exit_non_zero_unless_git_installed()
{
  if ! hash git 2> /dev/null; then
    echo error: git is not installed
    exit 42
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
exit_non_zero_unless_docker_installed()
{
  if ! hash docker; then
    echo error: docker is not installed
    exit 42
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
set_git_repo_dir()
{
  local -r src_dir="${1:-${PWD}}"
  local -r abs_src_dir="$(cd "${src_dir}" && pwd)"
  echo "Checking ${abs_src_dir}"
  echo 'Looking for uncommitted changes'
  if [[ -z $(cd ${abs_src_dir} && git status -s) ]]; then
    echo 'Found none'
    echo "Using ${abs_src_dir}"
    GIT_REPO_DIR="${abs_src_dir}"
  else
    echo 'Found some'
    local -r url="${TMP_DIR}/$(basename ${abs_src_dir})"
    echo "So copying it to ${url}"
    cp -r "${abs_src_dir}" "${TMP_DIR}"
    echo "Committing the changes in ${url}"
    cd ${url}
    git config user.email 'cyber-dojo-machine-user@cyber-dojo.org'
    git config user.name 'CyberDojoMachineUser'
    git add .
    git commit -m 'Save'
    echo "Using ${url}"
    GIT_REPO_DIR="${url}"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
stderr()
{
  >&2 echo "${1}"
}

# - - - - - - - - - - - - - - - - - - - - - - -
git_commit_sha()
{
  echo "$(cd "${GIT_REPO_DIR}" && git rev-parse HEAD)"
}

# - - - - - - - - - - - - - - - - - - - - - - -
git_commit_tag()
{
  local -r sha="$(git_commit_sha)"
  echo "${sha:0:7}"
}

# - - - - - - - - - - - - - - - - - - - - - - -
cyber_dojo()
{
  local -r name=cyber-dojo
  if [ -x "$(command -v ${name})" ]; then
    stderr "Found executable ${name} on the PATH"
    echo "${name}"
  else
    local -r url="https://raw.githubusercontent.com/cyber-dojo/commander/master/${name}"
    stderr "Did not find executable ${name} on the PATH"
    stderr "Curling it from ${url}"
    curl --fail --output "${TMP_DIR}/${name}" --silent "${url}"
    chmod 700 "${TMP_DIR}/${name}"
    echo "${TMP_DIR}/${name}"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - -
build_cdl_image()
{
  echo "Creating file ${GIT_REPO_DIR}/docker/Dockerfile from ${GIT_REPO_DIR}/docker/Dockerfile.base"
  cat "${GIT_REPO_DIR}/docker/Dockerfile.base" \
    | \
      docker run \
        --interactive \
        --rm \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        cyberdojofoundation/image_dockerfile_augmenter \
    > \
      "${GIT_REPO_DIR}/docker/Dockerfile"

  echo "Building image $(image_name) from ${GIT_REPO_DIR}/docker/Dockerfile"
  docker build \
    --build-arg GIT_COMMIT_SHA="$(git_commit_sha)" \
    --compress \
    --file "${GIT_REPO_DIR}/docker/Dockerfile" \
    --tag "$(image_name)" \
    "${GIT_REPO_DIR}/docker"
}

#- - - - - - - - - - - - - - - - - - - - - - -
image_name()
{
  docker run \
    --rm \
    --volume "${GIT_REPO_DIR}:/data:ro" \
    cyberdojofoundation/image_namer
}

# - - - - - - - - - - - - - - - - - - - - - - -
on_CI()
{
  [ -n "${CIRCLE_SHA1}" ]
}

# - - - - - - - - - - - - - - - - - - - - - - -
scheduled_CI()
{
  # when CI is running for a commit, this is the commit's username
  [ "${CIRCLE_USERNAME}" == "" ]
}

# - - - - - - - - - - - - - - - - - - - - - - -
testing_myself()
{
  # Don't push CDL images if building CDL images
  # as part of image_builder's own tests.
  [ "${CIRCLE_PROJECT_REPONAME}" = 'image_builder' ]
}

# - - - - - - - - - - - - - - - - - - - - - - -
has_start_point()
{
  [ -d "${GIT_REPO_DIR}/start_point" ]
}

# - - - - - - - - - - - - - - - - - - - - - - -
check_version()
{
  echo 'No ${GIT_REPO_DIR}/start_point/ dir so assuming base-language repo'
  # TODO: check the script exists before calling it
  "${GIT_REPO_DIR}/check_version.sh"
}

# - - - - - - - - - - - - - - - - - - - - - - -
tag_cdl_image_with_commit_sha()
{
  docker tag $(image_name) $(image_name):$(git_commit_tag)
  echo "Successfully tagged to $(image_name):$(git_commit_tag)"
}

# - - - - - - - - - - - - - - - - - - - - - - -
push_cdl_images_to_dockerhub()
{
  echo "Pushing $(image_name) to dockerhub"
  # DOCKER_PASSWORD, DOCKER_USERNAME must be in the CI context
  echo "${DOCKER_PASSWORD}" | docker login --username "${DOCKER_USERNAME}" --password-stdin
  docker push $(image_name)
  echo "Successfully pushed $(image_name) to dockerhub"
  docker push $(image_name):$(git_commit_tag)
  echo "Successfully pushed $(image_name):$(git_commit_tag) to dockerhub"
  docker logout
}

# - - - - - - - - - - - - - - - - - - - - - - -
versioner_env_vars()
{
  docker run --rm cyberdojo/versioner:latest
}

# - - - - - - - - - - - - - - - - - - - - - - -
export $(versioner_env_vars)
exit_zero_if_show_help ${*}
exit_non_zero_unless_git_installed
exit_non_zero_unless_docker_installed
exit_non_zero_unless_good_GIT_REPO_DIR ${*}
set_git_repo_dir ${*}
build_cdl_image
tag_cdl_image_with_commit_sha

if ! has_start_point; then
  check_version
fi

if on_CI && ! scheduled_CI && ! testing_myself; then
  push_cdl_images_to_dockerhub
else
  echo Not pushing image to dockerhub
  echo Not notifying dependent repos
fi
