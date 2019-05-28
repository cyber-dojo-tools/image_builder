
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

repo_url()
{
  local NAME="${1}"
  local STRAIGHT_PATH=`absPath "${ROOT_DIR}/../${1}"`
  local CURLED_PATH="${SHUNIT_TMPDIR}/${1}"
  if [ -d "${STRAIGHT_PATH}" ]; then
    echo "${STRAIGHT_PATH}"
  elif [ ! -d "${CURLED_PATH}" ]; then
    local GITHUB_ORG=https://github.com/cyber-dojo-languages
    local REPO_NAME="${1}.git"
    local REPO_URL="${GITHUB_ORG}/${REPO_NAME}"
    mkdir -p "${CURLED_PATH}"
    git clone --single-branch --branch master --depth 1 "${REPO_URL}" "${CURLED_PATH}"
    echo "${CURLED_PATH}"
  else
    echo "${CURLED_PATH}"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertBuildImage()
{
  build_image $1
  assertTrue $?
}

build_image()
{
  local src_dir=$1
  ${ROOT_DIR}/run_build_image.sh ${src_dir} > >(tee ${stdoutF}) 2> >(tee ${stderrF} >&2)
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
