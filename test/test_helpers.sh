
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

assertBuildImage()
{
  echo "ROOT_DIR=${ROOT_DIR}"
  echo "$one=${1}"
  local src_dir=${ROOT_DIR}$1
  echo "src_dir=${src_dir}"
  ${ROOT_DIR}/run_build_image.sh ${src_dir} >${stdoutF} 2>${stderrF}
  local status=$?
  echo "status=${status}"
  #build_image $1
  #cat ${stdoutF}
  assertTrue ${status}
  echo 'A'
  assertNoStderr
  echo 'B'
}

build_image()
{
  local src_dir=${ROOT_DIR}$1
  ${ROOT_DIR}/run_build_image.sh ${src_dir} >${stdoutF} 2>${stderrF}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertAlpineImageBuilt()
{
  assertImageBuilt
  assertStdoutIncludes "adduser -D -G cyber-dojo -h /home/flamingo -s '/bin/sh' -u 40014 flamingo"
  assertStdoutIncludes 'Welcome to Alpine Linux'
}

assertUbuntuImageBuilt()
{
  assertImageBuilt
  assertStdoutIncludes "adduser --disabled-password --gecos \"\" --ingroup cyber-dojo --home /home/flamingo --uid 40014 flamingo"
  assertStdoutIncludes 'Ubuntu'
}

assertImageBuilt()
{
  assertStdoutIncludes '# build_the_image'
  assertStdoutIncludes '# print_image_info'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertStartPointCreated()
{
  assertStdoutIncludes '# check_start_point_can_be_created'
}

refuteStartPointCreated()
{
  refuteStdoutIncludes '# check_start_point_can_be_created'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertStartPointRedAmberGreenStateful()
{
  assertStdoutIncludes '# check_start_point_src_red_green_amber_using_runner_stateful'
  assertRedAmberGreen
}

assertStartPointRedAmberGreenStateless()
{
  assertStdoutIncludes '# check_start_point_src_red_green_amber_using_runner_stateless'
  assertRedAmberGreen
}

assertRedAmberGreen()
{
  assertStdoutIncludes 'red: OK'
  assertStdoutIncludes 'green: OK'
  assertStdoutIncludes 'amber: OK'
}

refuteRedAmberGreen()
{
  refuteStdoutIncludes 'red: OK'
  refuteStdoutIncludes 'green: OK'
  refuteStdoutIncludes 'amber: OK'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -