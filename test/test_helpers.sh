
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

assertBuildImage()
{
  build_image $1
  assertTrue $?
  assertNoStderr
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

readonly startPointCreatedMessage='check_start_point_can_be_created'

assertStartPointCreated()
{
  assertStdoutIncludes "# ${startPointCreatedMessage}"
}

refuteStartPointCreated()
{
  refuteStdoutIncludes "# ${startPointCreatedMessage}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly startPointRedAmberGreenMessage='check_start_point_src_red_green_amber_using_runner'

assertStartPointRedAmberGreenStateful()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}_stateful"
  assertRedAmberGreen
}

assertStartPointRedAmberGreenStateless()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}_stateless"
  assertRedAmberGreen
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly redMessageOK='red: OK'
readonly amberMessageOK='amber: OK'
readonly greenMessageOK='green: OK'

assertRedAmberGreen()
{
  assertStdoutIncludes ${redMessageOK}
  assertStdoutIncludes ${amberMessageOK}
  assertStdoutIncludes ${greenMessageOK}
}

refuteRedAmberGreen()
{
  refuteStdoutIncludes ${redMessageOK}
  refuteStdoutIncludes ${amberMessageOK}
  refuteStdoutIncludes ${greenMessageOK}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -
