
lambda { |stdout,stderr,status|
  output = stdout + stderr
  hunit_pattern = /Counts \{cases = (\d+), tried = (\d+), errors = (\d+), failures = (\d+)\}/
  if match = hunit_pattern.match(output)
    return :amber if match[3] != '0'
    return :red   if match[4] != '0'
    return :green
  else
    return :amber
  end
}
