
def print(lines, stream)
  lines.each { |line| stream.puts line }
end

def log(lines)
  print(lines, STDERR)
end

def warning(lines)
  log(['WARNING'] + lines)
end

def failed(lines)
  log(['FAILED'] + lines)
  exit fail
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def banner_line
  '-' * 42
end

def banner(title)
  print([ '', banner_line, title, ], STDOUT)
end

def banner_end
  print([ 'OK', banner_line ], STDOUT)
end
