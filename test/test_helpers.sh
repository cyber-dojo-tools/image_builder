
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

repo_url()
{
  local name="${1}"
  local straight_path="${ROOT_DIR}/../${name}"
  local curled_path="${SHUNIT_TMPDIR}/${name}"
  if [ -d "${straight_path}" ]; then
    echo "${straight_path}"
  elif [ ! -d "${curled_path}" ]; then
    local github_org=https://github.com/cyber-dojo-languages
    local repo_url="${github_org}/${name}"
    mkdir -p "${curled_path}"
    git clone --single-branch --branch master --depth 1 "${repo_url}" "${curled_path}"
    echo "${curled_path}"
  else
    echo "${curled_path}"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertBuildImage()
{
  build_image $1
  local ok=$?
  local nl=$'\n'
  local stdout="<STDOUT>${newline}$(cat ${stdoutF})${newline}</STDOUT>${newline}"
  local stderr="<STDERR>${newline}$(cat ${stderrF})${newline}</STDERR>${newline}"
  assertTrue "${stdout}${stderr}" ${ok}
}

build_image()
{
  local src_dir=$1
  #${ROOT_DIR}/run_build_image2.sh ${src_dir} > >(tee ${stdoutF}) 2> >(tee ${stderrF} >&2)
  ${ROOT_DIR}/run_build_image2.sh ${src_dir} > ${stdoutF} 2> ${stderrF}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertAlpineImageBuilt()
{
  assertStdoutIncludes "# Alpine based image built OK"
}

assertUbuntuImageBuilt()
{
  assertStdoutIncludes '# Ubuntu based image built OK'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertSandboxUserPresent()
{
  assertStdoutIncludes '# show_sandbox_user'
  assertStdoutIncludes '# 41966:51966 == uid:gid(sandbox)'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly startPointCreatedMessage='start-point image can be created'

assertStartPointCreated()
{
  assertStdoutIncludes "# ${startPointCreatedMessage}"
}

refuteStartPointCreated()
{
  refuteStdoutIncludes "# ${startPointCreatedMessage}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertStartPointRedAmberGreen()
{
  assertRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly redMessageOK='# red: OK'
readonly amberMessageOK='# amber: OK'
readonly greenMessageOK='# green: OK'

assertRedAmberGreen()
{
  assertStdoutIncludes "${redMessageOK}"
  assertStdoutIncludes "${amberMessageOK}"
  assertStdoutIncludes "${greenMessageOK}"
}

refuteRedAmberGreen()
{
  refuteStdoutIncludes "${redMessageOK}"
  refuteStdoutIncludes "${amberMessageOK}"
  refuteStdoutIncludes "${greenMessageOK}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
