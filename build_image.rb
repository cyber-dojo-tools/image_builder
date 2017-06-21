#!/usr/bin/env ruby

# This is the main entry-point for the image_builder
# docker-image which includes docker-compose inside it.

#TODO: get my_dir programmatically
#TODO: add --verbose option which prints shell-log

def success; 0; end

def docker_username; ENV['DOCKER_USERNAME']; end
def docker_password; ENV['DOCKER_PASSWORD']; end
def src_dir        ; ENV['SRC_DIR'        ]; end

def volume_name; 'language'; end

def space; ' '; end

def my_dir; '/app'; end

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
  # shows command's interactive output
  system(command)
  status = $?.exitstatus
  unless status == success
    failed [ command, "exit_status == #{status}" ]
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

def check_required_env_vars
  [ 'DOCKER_USERNAME', 'DOCKER_PASSWORD', 'SRC_DIR' ].each do |name|
    var = ENV[name]
    failed [ "#{name} environment-variable not set "] if var.nil?
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def create_src_dir_volume
  assert_shell "docker volume create --name=#{volume_name}"
  command = [
    'docker create',
      '--interactive',
      '--tty',
      "--volume=#{volume_name}:/repo",
        'cyberdojo/runner',
          'sh'
  ].join(space)
  cid = assert_shell(command)
  assert_shell "docker cp #{src_dir}/. #{cid}:/repo"
  assert_shell "docker rm -f #{cid}"
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
create_src_dir_volume

docker_compose 'up -d runner'
docker_compose 'up -d runner_stateless'

wait_till_up 'cyber-dojo-runner'
wait_till_up 'cyber-dojo-runner-stateless'

begin
  assert_system [
    'docker-compose',
      "--file #{my_dir}/docker-compose.yml",
      'run',
        "-e DOCKER_USERNAME=#{docker_username}",
        "-e DOCKER_PASSWORD=#{docker_password}",
        "-e SRC_DIR=#{src_dir}",
          'image_builder_inner',
            '/app/build_image.rb'
    ].join(space)

ensure
  docker_compose 'down'
  wait_till_exited 'cyber-dojo-runner'
  wait_till_exited 'cyber-dojo-runner-stateless'
  wait_till_exited 'cyber-dojo-image-builder'
  shell("docker volume rm #{volume_name}")
end
