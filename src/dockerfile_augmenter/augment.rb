
# reads a Dockerfile on stdin and
# writes a Dockerfile on stdout
# augmented to fulful runner's requirements.

def dockerfile
  $dockerfile ||= STDIN.read
end

def from
  from_line = dockerfile.lines.find{ |line| line.strip.start_with?('FROM') }
  from_line.split[1]
end

def etc_issue
  `docker run --rm -i #{from} sh -c 'cat /etc/issue'`
end

def alpine?
  etc_issue.include?('Alpine')
end

def added
  if alpine?
    [
      "# Augmented commands to satify runner's requirements",
      'RUN echo "Hello from AUGMENTED Alpine" > alpine.txt'
    ]
  end
end

def split(dockerfile)
  lines = dockerfile.lines
  header = lines[0..1]
  body = lines[2..-1]
  [header,body]
end

header,body = split(dockerfile)

header.each { |line| puts line }
 added.each { |line| puts line }
  body.each { |line| puts line }
