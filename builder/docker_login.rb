
def docker_login
  banner __method__.to_s
  if docker_username == ''
    failed [ "#{docker_username_env_var} env-var not set" ]
  end
  if docker_password == ''
    failed [ "#{docker_password_env_var} env-var not set" ]
  end
  # careful not to show password if command fails
  output = `#{docker_login_cmd(docker_username, docker_password)}`
  status = $?.exitstatus
  unless status == success
    failed [
      "#{docker_login_cmd('[secure]','[secure]')}",
      "exit_status == #{status}",
      output
    ]
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_login_cmd(username, password)
  # TODO: Try this several times before failing?
  [ 'docker login',
      "--username #{username}",
      "--password #{password}"
  ].join(' ')
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def success; 0; end

def docker_username_env_var; 'DOCKER_USERNAME'; end
def docker_password_env_var; 'DOCKER_PASSWORD'; end

def docker_username; ENV[docker_username_env_var]; end
def docker_password; ENV[docker_password_env_var]; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def banner(title)
  print([ '', banner_line, title, ], STDOUT)
end

def banner_end
  print([ 'OK', banner_line ], STDOUT)
end

def banner_line
  '-' * 42
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def failed(lines)
  log(['FAILED'] + lines)
  exit 1
end

def log(lines)
  print(lines, STDERR)
end

def print(lines, stream)
  lines.each { |line| stream.puts line }
end
