lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :red   if /=== FAILURES ===/.match(output)
  return :green if /=== (\d+) passed/.match(output)
  return :amber
}