#!/usr/bin/env ruby

# This is the main entry-point for the image_builder
# docker-image which includes docker-compose inside it.

#TODO: add --verbose option which prints shell-log

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

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

def check_required_env_vars
  if running_on_travis?
    env_vars = [ 'SRC_DIR', 'DOCKER_USERNAME', 'DOCKER_PASSWORD' ]
  else
    env_vars = [ 'SRC_DIR' ]
  end
  env_vars.each do |name|
    var = ENV[name]
    failed [ "#{name} environment-variable not set "] if var.nil?
  end
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

def wait_till_up(service_name)
  max_wait = 5 # seconds
  up = false
  tries = 0
  while !up && tries < (max_wait / 0.2)
    up = up?(service_name)
    assert_shell('sleep 0.2') unless up
    tries += 1
  end
  if !up? service_name
    failed [ "#{service_name} not running" ]
    #docker logs ${1}
    exit 1
  end
end

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

def wait_till_exited(service_name)
  max_wait = 5 # seconds
  exited = false
  tries = 0
  while !exited && tries < (max_wait / 0.2)
    exited = exited?(service_name)
    assert_shell('sleep 0.2') unless exited
    tries += 1
  end
  if !exited? service_name
    failed [ "#{service_name} not exited" ]
    #docker logs ${1}
    exit 1
  end
end

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

check_required_env_vars

docker_compose 'up -d runner'
docker_compose 'up -d runner_stateless'

wait_till_up 'cyber-dojo-runner'
wait_till_up 'cyber-dojo-runner-stateless'

begin
  assert_system [
    'docker-compose',
      "--file #{my_dir}/docker-compose.yml",
      'run',
        "-e DOCKER_USERNAME=#{ENV['DOCKER_USERNAME']}",
        "-e DOCKER_PASSWORD=#{ENV['DOCKER_PASSWORD']}",
        "-e TRAVIS=#{ENV['TRAVIS']}",
        "-e SRC_DIR=#{ENV['SRC_DIR']}",
          'image_builder_inner',
            '/app/build_image.rb'
    ].join(space)

ensure
  docker_compose 'down'
  wait_till_exited 'cyber-dojo-runner'
  wait_till_exited 'cyber-dojo-runner-stateless'
  wait_till_exited 'cyber-dojo-image-builder'
end
