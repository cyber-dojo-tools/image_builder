
assertStdoutEquals() { assertEquals 'stdout' "$1" "`cat ${stdoutF}`"; }
assertStderrEquals() { assertEquals 'stderr' "$1" "`cat ${stderrF}`"; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertNoStdout() { assertStdoutEquals ""; }
assertNoStderr() { assertStderrEquals ""; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

assertStdoutIncludes()
{
  local expected=$1
  local stdout="`cat ${stdoutF}`"
  if [[ "${stdout}" != *"${expected}"* ]]; then
    dumpStdout
    fail "expected stdout to include ${expected}"
  fi
}

refuteStdoutIncludes()
{
  local unexpected=$1
  local stdout="`cat ${stdoutF}`"
  if [[ "${stdout}" == *"${unexpected}"* ]]; then
    dumpStdout
    fail "did not expect stdout to include ${unexpected}"
  fi
}

assertStderrIncludes()
{
  local expected=$1
  local stderr="`cat ${stderrF}`"
  if [[ "${stderr}" != *"${expected}"* ]]; then
    dumpStderr
    fail "expected stderr to include ${expected}"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

oneTimeSetUp()
{
  outputDir="${SHUNIT_TMPDIR}/output"
  mkdir "${outputDir}"
  stdoutF="${outputDir}/stdout"
  stderrF="${outputDir}/stderr"
  mkdirCmd='mkdir'  # save command name in variable to make future changes easy
  testDir="${SHUNIT_TMPDIR}/some_test_dir"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

dumpStdout()
{
  echo "<STDOUT>"
  cat ${stdoutF}
  echo "</STDOUT>"
}

dumpStderr()
{
  echo "<STDERR>"
  cat ${stderrF}
  echo "</STDERR>"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

absPath()
{
  #use like this [ local resolved=`abspath ./../a/b/c` ]
  cd "$(dirname "$1")"
  printf "%s/%s\n" "$(pwd)" "$(basename "$1")"
}
