
lambda { |stdout, stderr, status|
  output = stdout + stderr
  return :red   if /(.*)Assertion(.*)failed./.match(output)
  return :green if /(All|\d+) tests passed/.match(output)
  return :amber
}
