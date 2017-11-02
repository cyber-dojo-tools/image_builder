
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
  assertStdoutIncludes "Alpine image built OK"
}

assertUbuntuImageBuilt()
{
  assertStdoutIncludes 'Ubuntu image built OK'
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertAlpineAvatarUsersAdded()
{
  assertStdoutIncludes "adduser -D -G cyber-dojo -h /home/flamingo -s '/bin/sh' -u 40014 flamingo"
}

assertUbuntuAvatarUsersAdded()
{
  assertStdoutIncludes "adduser --disabled-password --gecos \"\" --ingroup cyber-dojo --home /home/flamingo --uid 40014 flamingo"
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
