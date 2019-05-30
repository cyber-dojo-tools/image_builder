
lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :green if status == 0
  return :red   if /Looks like you planned (\d+) test(s?) but ran (\d+)/.match(output)
  return :amber if status == 255
  return :red
}
