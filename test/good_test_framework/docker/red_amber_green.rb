
lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :red if /^TEST RUN FAILED/.match(output)
  return :green if /^TEST RUN PASSED/.match(output)
  return :amber
}
