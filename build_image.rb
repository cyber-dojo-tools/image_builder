#!/usr/bin/env ruby

# This is the main entry-point for the image_builder
# docker-image which includes docker-compose inside it.

#TODO?: add --verbose option to main docker-compose call

def success; 0; end
def space; ' '; end
def my_dir; File.dirname(__FILE__); end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def shell(command)
  # does not show command's interactive output
  output = `#{command}`
  status = $?.exitstatus
  #log( [ "command=:#{command}:"] )
  #log( [ "status=:#{status}:" ])
  #log( [ "output=:#{output}:" ])
  return output.strip, status
end

def assert_shell(command)
  # does not show command's interactive output
  output,status = shell(command)
  unless status == success
    failed [ command, "exit_status == #{status}", output ]
  end
  output.strip
end

def assert_system(command)
  # does show command's interactive output but
  # does not show the command in failed diagnostic
  # because it contains DOCKER_PASSWORD
  system(command)
  status = $?.exitstatus
  unless status == success
    failed [ "exit_status == #{status}" ]
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_compose(command)
  assert_shell([
    'docker-compose',
      "--file #{my_dir}/docker-compose.yml",
        command
  ].join(space))
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def wait_till(method_name, service_name)
  max_wait = 5 # seconds
  one_wait = 0.2 # seconds
  done = false
  tries = 0
  while !done && tries < (max_wait / one_wait)
    done = Object.send(method_name, service_name)
    assert_shell("sleep #{one_wait}") unless done
    tries += 1
  end
  unless Object.send(method_name, service_name)
    failed [ "#{service_name} never #{method_name}" ]
    #docker logs #{service_name}
    exit 1
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def up?(service_name)
  command = [
    'docker ps',
      '--all',
      '--filter status=running',
      "--format '{{.Names}}'",
        '|',
           "grep ^#{service_name}$"
  ].join(space)
  up,_ = shell(command)
  up == service_name
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def exited?(service_name)
  command = [
    'docker ps',
      '--all',
      "--format '{{.Names}}'",
        '|',
           "grep ^#{service_name}$"
  ].join(space)
  exited,_ = shell(command)
  exited != service_name
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def env_var(name)
  value = ENV[name]
  "-e #{name}=#{value}"
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

docker_compose 'up -d runner'
docker_compose 'up -d runner_stateless'

service_names = %w( cyber-dojo-runner cyber-dojo-runner-stateless )
service_names.each do |name|
  wait_till :up?, name
end

begin
  assert_system [
    'docker-compose',
      "--file #{my_dir}/docker-compose.yml",
      'run',
        env_var('DOCKER_USERNAME'),
        env_var('DOCKER_PASSWORD'),
        env_var('GITHUB_TOKEN'),
        env_var('SRC_DIR'),
        env_var('TRAVIS'),
          'image_builder_inner',
            '/app/build_image.rb'
    ].join(space)
ensure
  docker_compose 'down'
  (service_names + [ 'cyber-dojo-image-builder' ]).each do |name|
    wait_till :exited?, name
  end
end
