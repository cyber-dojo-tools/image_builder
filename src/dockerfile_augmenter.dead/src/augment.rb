
# reads a Dockerfile on stdin and
# writes a Dockerfile on stdout
# augmented to fulful runner's requirements.

# - - - - - - - - - - - - - - - - -

def dockerfile
  $dockerfile ||= STDIN.read
end

# - - - - - - - - - - - - - - - - -

def from_image_name
  from_line = dockerfile.lines.find { |line| line.start_with?('FROM') }
  from_line.split[1]
end

# - - - - - - - - - - - - - - - - -

def etc_issue
  $etc_issue ||= `docker run --rm -i #{from_image_name} sh -c 'cat /etc/issue'`
end

# - - - - - - - - - - - - - - - - -

def os
  if etc_issue.include?('Alpine')
    return :Alpine
  end
  if etc_issue.include?('Ubuntu')
    return :Ubuntu
  end
  if etc_issue.include?('Debian')
    return :Debian
  end
  # else failed...
end

# - - - - - - - - - - - - - - - - -

def add_sandbox_group
  # Must be idempotent because Dockerfile could be
  # based on a docker-image which _already_ has been
  # through image-builder processing
  name = 'sandbox'
  gid = '51966'
  option = case os
  when :Alpine         then '-g'
  when :Debian,:Ubuntu then '--gid'
  end
  group_exists = "getent group #{name}"
  add_group = "addgroup #{option} #{gid} #{name}"
  "RUN (#{group_exists}) || (#{add_group})"
end

# - - - - - - - - - - - - - - - - -

def add_sandbox_user
  # Must be idempotent because Dockerfile could be
  # based on a docker-image which _already_ has been
  # through image-builder processing
  home_dir = '/home/sandbox'
  name = 'sandbox'
  shell = '/bin/bash'
  uid = '41966'
  options = case os
  when :Alpine then [
      '-D',                # --disabled-password
      '-g ""',             # --gecos
      "-h #{home_dir}",    # --home
      "-G #{name}",        # --ingroup
      "-s #{shell}",       # --shell
      "-u #{uid}"          # --uid
    ].join(' ')
  when :Ubuntu, :Debian then [
      '--disabled-password',
      '--gecos ""',
      "--home #{home_dir}",
      "--ingroup #{name}",
      "--shell #{shell}",
      "--uid #{uid}"
    ].join(' ')
  end
  user_exists = "grep -q #{name}:x:#{uid} /etc/passwd"
  add_user = "adduser #{options} #{name}"
  "RUN (#{user_exists}) || (#{add_user})"
end

# - - - - - - - - - - - - - - - - -

def install_runner_dependencies
  [ add_sandbox_group,
    add_sandbox_user,
    install(coreutils,bash,tar,file)
  ]
end

# - - - - - - - - - - - - - - - - - - - - - - - - - -

def install(*packages)
  case os
  when :Alpine
    apk_install(packages)
  when :Debian,:Ubuntu
    apt_get_install(packages)
  end
end

def apk_install(packages)
  "RUN apk add --update #{packages.join(' ')}"
end

# - - - - - - - - - - - - - - - - -

def apt_get_install(packages)
  "RUN apt-get update && apt-get install --yes #{packages.join(' ')}"
end

# - - - - - - - - - - - - - - - - -

def coreutils
  # On default Alpine date-time file-stamps are stored
  # to a one second granularity. In other words, the
  # microseconds are always zero. Viz
  #   $ docker run --rm -it alpine:latest sh
  #   / # echo 'hello' > hello.txt
  #   / # stat -c "%y%" hello.txt
  #   2017-11-09 20:09:22.000000000
  # So:
  #   $ docker run --rm -it alpine:latest sh
  #   / # apk add --update coreutils
  #   / # echo 'hello' > hello.txt
  #   / # stat -c "%y%" hello.txt
  #   2017-11-09 20:11:09.376824357 +0000
  'coreutils'
end

# - - - - - - - - - - - - - - - - - - - - - - - - - -

def bash
  # On Alpine install bash so runner can reply on
  # all containers having bash.
  'bash'
end

# - - - - - - - - - - - - - - - - -

def tar
  # The runner docker-tar-pipes text files into the
  # test-framework container using the --touch option
  # to set their date-time stamps. The default Alpine tar
  # does not support the --touch option hence the update.
  'tar'
end

# - - - - - - - - - - - - - - - - -

def file
  # Each runner docker-tar-pipes text files out of the
  # test-framework container. It does this using
  # $ file --mime-encoding ${filename}
  'file'
end

# - - - - - - - - - - - - - - - - -

def add_sandbox_group
  # Must be idempotent because Dockerfile could be
  # based on a docker-image which _already_ has been
  # through image-builder processing
  name = 'sandbox'
  gid = '51966'
  option = case os
  when :Alpine         then '-g'
  when :Debian,:Ubuntu then '--gid'
  end
  group_exists = "getent group #{name}"
  add_group = "addgroup #{option} #{gid} #{name}"
  "RUN (#{group_exists}) || (#{add_group})"
end

# - - - - - - - - - - - - - - - - -

def add_sandbox_user
  # Must be idempotent because Dockerfile could be
  # based on a docker-image which _already_ has been
  # through image-builder processing
  home_dir = '/home/sandbox'
  name = 'sandbox'
  shell = '/bin/bash'
  uid = '41966'
  options = case os
  when :Alpine then [
      '-D',                # --disabled-password
      '-g ""',             # --gecos
      "-h #{home_dir}",    # --home
      "-G #{name}",        # --ingroup
      "-s #{shell}",       # --shell
      "-u #{uid}"          # --uid
    ].join(' ')
  when :Ubuntu, :Debian then [
      '--disabled-password',
      '--gecos ""',
      "--home #{home_dir}",
      "--ingroup #{name}",
      "--shell #{shell}",
      "--uid #{uid}"
    ].join(' ')
  end
  user_exists = "grep -q #{name}:x:#{uid} /etc/passwd"
  add_user = "adduser #{options} #{name}"
  "RUN (#{user_exists}) || (#{add_user})"
end

# - - - - - - - - - - - - - - - - - - - - - - - - - -

def banner_start
  [
    '',
    '# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>',
    "# START of extra commands to fulfil runner's requirements (os=#{os})",
    ''
  ]
end

# - - - - - - - - - - - - - - - - - - - - - - - - - -

def banner_end
  [
    '',
    "# END of extra commands to fulfil runner's requirements",
    '# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>',
    ''
  ]
end

# - - - - - - - - - - - - - - - - - - - - - - - - - -

def split(dockerfile)
  lines = dockerfile.lines
  index = lines.index { |line| line.start_with?('FROM') }
  from = lines[0..index]
  body = lines[index+1..-1]
  [from,body]
end

# - - - - - - - - - - - - - - - - - - - - - - - - - -

from,body = split(dockerfile)
parts = []
parts << from
parts << banner_start
parts << install_runner_dependencies
parts << banner_end
parts << body

parts.each do |part|
 part.each do |line|
   puts line
 end
end
