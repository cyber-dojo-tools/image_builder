#!/usr/bin/env ruby

require_relative 'dependencies'
require 'json'

def repo_url       ; ENV['REPO_URL'       ]; end
def docker_username; ENV['DOCKER_USERNAME']; end
def docker_password; ENV['DOCKER_PASSWORD']; end

def      docker_dir; '/docker'     ; end
def start_point_dir; '/start_point'; end

def from
  dockerfile = IO.read("#{docker_dir}/Dockerfile")
  lines = dockerfile.split("\n")
  from_line = lines.find { |line| line.start_with? 'FROM' }
  from_line.split[1].strip
end

def language_repo?
  File.exists?("#{docker_dir}/manifest.json") &&
    !Dir.exists?(start_point_dir)
end

def test_framework_repo?
  !File.exists?("#{docker_dir}/manifest.json") &&
    Dir.exists?(start_point_dir)
end

def json_image_name(filename)
  manifest = IO.read(filename)
  json = JSON.parse(manifest)
  json['image_name']
end

def image_name
  if language_repo?
    return json_image_name("#{docker_dir}/manifest.json")
  end
  if test_framework_repo?
    return json_image_name("#{start_point_dir}/manifest.json")
  end
  return nil
end

def print(lines, stream)
  lines.each { |line| stream.puts line }
end

def print_diagnostic(lines)
  print(lines, STDERR)
end

def banner_line
  '=' * 42
end

def banner(title)
  print([ '', banner_line, title.upcase, ], STDOUT)
end

def banner_end
  print([ 'OK', banner_line, '', '' ], STDOUT)
end

def verify_dependency_settings
  banner __method__.to_s
  status = dependencies.include?([ repo_url, from, image_name ])
  unless status
    print_diagnostic [
      'ERROR: cannot find dependency entry for',
      "  repo_url:#{repo_url}",
      "  from:#{from}",
      "  image_name:#{image_name}"
    ]
    exit status
  end
  banner_end
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
  banner __method__.to_s
  assert_system "cd #{docker_dir} && docker build --tag #{image_name} ."
  banner_end
end

def check_start_point
  banner __method__.to_s
  script = 'cyber-dojo'
  url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
  assert_system "curl -O #{url}"
  assert_system "chmod +x #{script}"
  name = 'checking'
  assert_system "./#{script} start-point create #{name} --git=#{repo_url}"
  assert_system "./#{script} start-point rm #{name}"
  banner_end
end

def push_the_image
  banner __method__.to_s
  command = [
    'docker login',
    "--username #{docker_username}",
    "--password #{docker_password}"
  ].join(' ')
  assert_system command
  assert_system "docker push #{image_name}"
  assert_system 'docker logout'
  banner_end
end

verify_dependency_settings
build_the_image
if test_framework_repo?
  check_start_point
  #check_traffic_lights/ (using runner)
  #check_outputs/
end
push_the_image


