
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

repo_url()
{
  local name="${1}"
  # Running locally when offline is handy sometimes
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

assert_build_image()
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
  #${ROOT_DIR}/run_build_image.sh ${src_dir} > >(tee ${stdoutF}) 2> >(tee ${stderrF} >&2)
  ${ROOT_DIR}/run_build_image2.sh ${src_dir} > ${stdoutF} 2> ${stderrF}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

image_name_from_stdout()
{
  local stdout=$(cat "${stdoutF}")
  [[ "${stdout}" =~ Successfully[[:space:]]created[[:space:]]docker-image[[:space:]]([^[:space:]]+) ]] && echo ${BASH_REMATCH[1]}
}

assert_image_OS()
{
  local image_name="${1}"
  local os="${2}"
  local etc_issue=$(docker run --rm -i "${image_name}" bash -c 'cat /etc/issue')
  local diagnostic="${image_name} is NOT based on ${os}...(${etc_issue})"
  grep --silent "${os}" <<< "${etc_issue}"
  assertTrue "${diagnostic}" $?
  echo -e "\t- image-name is ${image_name}"
  echo -e "\t- the OS is ${os}"
}

assert_sandbox_user_in()
{
  local image_name="${1}"
  local sandbox_user='sandbox:x:41966:51966:'
  local etc_passwd=$(docker run --rm -i "${image_name}" bash -c 'cat /etc/passwd')
  local diagnostic="${image_name} does NOT have a sandbox user...${etc_passwd}"
  grep --silent "${sandbox_user}" <<< "${etc_passwd}"
  assertTrue "${diagnostic}" $?
  echo -e "\t- it has a sandbox user"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assert_start_point_created()
{
  local stdout=$(cat "${stdoutF}")
  local message='Successfully created start-point image'
  local diagnostic="start-point NOT created...${stdout}"
  grep --silent "${message}" <<< "${stdout}"
  assertTrue "${diagnostic}" $?
  echo -e "\t- start-point created ok"
}

refute_start_point_created()
{
  local stdout=$(cat "${stdoutF}")
  local message='Successfully created start-point image'
  local diagnostic="start-point NOT created...${stdout}"
  grep --silent "${message}" <<< "${stdout}"
  assertFalse "${diagnostic}" $?
  echo -e "\t- start-point not created as expected"
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
