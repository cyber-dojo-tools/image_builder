
# - - - - - - - - - - - - - - - - - - - - - - -
# notify github projects that use the built image as their base FROM image
# - - - - - - - - - - - - - - - - - - - - - - -
notify_dependent_projects()
{
  echo 'Notifying dependent projects'

  local -r commit_push=github_automated_commit_push.sh
  local -r curled_path="${TMP_DIR}/${commit_push}"
  local -r github_org=https://raw.githubusercontent.com/cyber-dojo
  local -r url="${github_org}/cyber-dojo/master/sh/circle-ci/${commit_push}"

  curl \
    --fail \
    --output "${curled_path}" \
    --silent \
    "${url}"
  chmod 700 "${curled_path}"

  local -r from_org=cyber-dojo-languages
  local -r from_repo="${CIRCLE_PROJECT_REPONAME}" # eg java
  local -r from_sha="${CIRCLE_SHA1}" # eg a9334c964f81800a910dc3d301543262161fbbff
  local -r to_org=cyber-dojo-languages

  ${curled_path} \
    "${from_org}" "${from_repo}" "${from_sha}" \
    "${to_org}" $(dependent_projects)

  echo 'Successfully notified dependent projects'
}

# - - - - - - - - - - - - - - - - - - - - - - -
dependent_projects()
{
  docker run \
    --rm \
    --volume "$(src_dir_abs):/data:ro" \
      cyberdojofoundation/image_dependents
}
