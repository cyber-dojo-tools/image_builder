#!/usr/bin/env ruby

require_relative 'dependencies'
require 'json'

def repo_name
  ARGV[0]
end

def docker_username
  ARGV[1]
end

def docker_password
  ARGV[2]
end

def from
  dockerfile = IO.read('/docker/Dockerfile')
  lines = dockerfile.split("\n")
  from_line = lines.find { |line| line.start_with? 'FROM' }
  from_line.split[1].strip
end

def base_language_repo?
  File.exists?('/docker/manifest.json') &&
    !Dir.exists?('/start_point')
end

def language_plus_test_repo?
  !File.exists?('/docker/manifest.json') &&
  Dir.exists?('/start_point')
end

def image_name
  if base_language_repo?
    manifest = IO.read('/docker/manifest.json')
    json = JSON.parse(manifest)
    return json['image_name']
  end
  if language_plus_test_repo?
    manifest = IO.read('/start_point/manifest.json')
    json = JSON.parse(manifest)
    return json['image_name']
  end
  return nil
end

def print_diagnostic(lines)
  lines.each { |line| STDERR.puts line }
end

def verify_dependency_settings
  status = dependencies.include?([ repo_name, from, image_name ])
  unless status
    print_diagnostic [
      'ERROR: cannot find dependency entry for',
      "  repo_name:#{repo_name}",
      "  from:#{from}",
      "  image_name:#{image_name}"
    ]
    exit status
  end
end

def assert_system(command)
  system(command)
  status = $?.exitstatus
  unless status == 0
    print_diagnostic [
      "FAILED:command:#{command}",
      "exit_status == #{status}"
    ]
    exit status
  end
end

def build_the_image
  assert_system "cd /docker && docker build --tag #{image_name} ."
end

def push_the_image
  command = [
    'docker login',
    "--username #{docker_username}",
    "--password #{docker_password}"
  ].join(' ')
  assert_system command
  assert_system "docker push #{image_name}"
  assert_system 'docker logout'
end

verify_dependency_settings
build_the_image
push_the_image


