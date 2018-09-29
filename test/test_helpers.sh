
readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

assertBuildImage()
{
  build_image $1
  assertTrue $?
}

build_image()
{
  local src_dir=${ROOT_DIR}$1
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

readonly startPointRedAmberGreenMessage='check_red_amber_green'

assertStartPointRedAmberGreenStateless()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}"
  assertStdoutIncludes "# using runner-stateless"
  assertRedAmberGreen
}

assertStartPointRedAmberGreenStateful()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}"
  assertStdoutIncludes "# using runner-stateful"
  assertRedAmberGreen
}

assertStartPointRedAmberGreenProcessful()
{
  assertStdoutIncludes "# ${startPointRedAmberGreenMessage}"
  assertStdoutIncludes "# using runner-processful"
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
