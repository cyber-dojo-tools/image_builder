#!/usr/bin/env ruby

def success; 0; end

def docker_username; ENV['DOCKER_USERNAME']; end
def docker_password; ENV['DOCKER_PASSWORD']; end
def github_token   ; ENV['GITHUB_TOKEN'   ]; end
def src_dir        ; ENV['SRC_DIR'        ]; end

def volume_name; 'language'; end

def space; ' '; end

def my_dir; '/app'; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def shell(command)
  output = `#{command}`
  status = $?.exitstatus
  log( [ "command=:#{command}:"] )
  log( [ "status=:#{status}:" ])
  log( [ "output=:#{output}:" ])
  return output, status
end

def assert_shell(command)
  output,status = shell(command)
  unless status == success
    failed [ command, "exit_status == #{status}", output ]
  end
  output
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
  cid = assert_shell(command).strip

  assert_shell("docker cp #{src_dir}/. #{cid}:/repo")
  assert_shell("docker rm -f #{cid}")
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_compose(command)
  assert_shell "docker-compose --file #{my_dir}/docker-compose.yml #{command}"
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def up?(service_name)
  up,_ = shell("docker ps --all --filter status=running --format '{{.Names}}' | grep ^#{service_name}$")
  up.strip == service_name
end

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def exited?(service_name)
  exited,_ = shell("docker ps --all --format '{{.Names}}' | grep ^#{service_name}$")
  exited.strip != service_name
end

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

create_src_dir_volume

docker_compose 'up -d runner'
docker_compose 'up -d runner_stateless'

wait_till_up 'cyber-dojo-runner'
wait_till_up 'cyber-dojo-runner-stateless'

docker_compose [
    'run',
      "-e DOCKER_USERNAME=#{docker_username}",
      "-e DOCKER_PASSWORD=#{docker_password}",
      # "-e GITHUB_TOKEN=#{github_token}",
      "-e SRC_DIR=#{src_dir}",
        'image_builder_inner',
          '/app/build_image.rb'
        ].join(space)

docker_compose 'down'

wait_till_exited 'cyber-dojo-runner'
wait_till_exited 'cyber-dojo-runner-stateless'

assert_shell("docker volume rm #{volume_name}")
