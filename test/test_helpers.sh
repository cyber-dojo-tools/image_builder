
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
  assertStdoutIncludes "# Alpine based image built OK"
}

assertUbuntuImageBuilt()
{
  assertStdoutIncludes '# Ubuntu based image built OK'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertAvatarUsersPresent()
{
  assertStdoutIncludes '# show_avatar_users_sample'
  assertStdoutIncludes '# 40000:5000 == uid:gid(alligator)'
  assertStdoutIncludes '# 40051:5000 == uid:gid(squid)'
  assertStdoutIncludes '# 40063:5000 == uid:gid(zebra)'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly startPointCreatedMessage='start point can be created'

assertStartPointCreated()
{
  assertStdoutIncludes "# ${startPointCreatedMessage}"
}

refuteStartPointCreated()
{
  refuteStdoutIncludes "# ${startPointCreatedMessage}"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

readonly startPointRedAmberGreenMessage='check_red_green_amber_using_runner'

assertStartPointRedAmberGreenStateless()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}_stateless"
  assertRedAmberGreen
}

assertStartPointRedAmberGreenStateful()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}_stateful"
  assertRedAmberGreen
}

assertStartPointRedAmberGreenProcessful()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}_processful"
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
