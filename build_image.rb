#!/usr/bin/env ruby

require_relative 'dependencies'
require 'json'

def success; 0; end
def fail   ; 1; end

def repo_url       ; ENV['REPO_URL'       ]; end
def docker_username; ENV['DOCKER_USERNAME']; end
def docker_password; ENV['DOCKER_PASSWORD']; end

def         docker_dir; '/docker'     ; end
def    start_point_dir; '/start_point'; end
def        outputs_dir; '/outputs'; end
def traffic_lights_dir; '/traffic_lights'; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def from
  dockerfile = IO.read("#{docker_dir}/Dockerfile")
  lines = dockerfile.split("\n")
  from_line = lines.find { |line| line.start_with? 'FROM' }
  from_line.split[1].strip
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def language_repo?
  File.exists?("#{docker_dir}/manifest.json") &&
    !Dir.exists?(start_point_dir)
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def test_framework_repo?
  !File.exists?("#{docker_dir}/manifest.json") &&
    Dir.exists?(start_point_dir)
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def json_image_name(filename)
  manifest = IO.read(filename)
  json = JSON.parse(manifest)
  json['image_name']
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def image_name
  if language_repo?
    return json_image_name("#{docker_dir}/manifest.json")
  end
  if test_framework_repo?
    return json_image_name("#{start_point_dir}/manifest.json")
  end
  return nil
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def print(lines, stream)
  lines.each { |line| stream.puts line }
end

def print_diagnostic(lines)
  print(lines, STDERR)
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def banner_line
  '=' * 42
end

def banner(title)
  print([ '', banner_line, title.upcase, ], STDOUT)
end

def banner_end
  print([ 'OK', banner_line, '', '' ], STDOUT)
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def assert_system(command)
  output = `#{command}`
  status = $?.exitstatus
  unless status == success
    print_diagnostic [
      "FAILED:command:#{command}",
      "exit_status == #{status}"
    ]
    exit fail
  end
  output
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def verify_dependency_settings
  banner __method__.to_s
  found = dependencies.include?([ repo_url, from, image_name ])
  unless found
    print_diagnostic [
      'ERROR: cannot find dependency entry for',
      "  repo_url:#{repo_url}",
      "  from:#{from}",
      "  image_name:#{image_name}"
    ]
    exit fail
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def build_the_image
  banner __method__.to_s
  assert_system "cd #{docker_dir} && docker build --tag #{image_name} ."
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_images_red_amber_green_lambda_file
  # TODO: improve diagnostics
  banner __method__.to_s
  rag_filename = '/usr/local/bin/red_amber_green.rb'
  output = assert_system "docker run --rm -it #{image_name} cat #{rag_filename}"
  fn = eval(output)
  rag = fn.call(stdout='ssd', stderr='sdsd', status=42)
  unless [:red,:amber,:green].include? rag
    print_diagnostic([
      "FAILED:image #{image_name}'s #{rag_filename} not in [:red,:amber,:green]"
    ])
    exit fail
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_start_point
  banner __method__.to_s
  script = 'cyber-dojo'
  url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
  assert_system "curl -O #{url}"
  assert_system "chmod +x #{script}"
  name = 'checking'
  assert_system "./#{script} start-point create #{name} --git=#{repo_url}"
  assert_system "./#{script} start-point rm #{name}"

  # TODO: check start_point is red

  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_outputs_colour(rag)
  dir = "#{outputs_dir}/#{rag}"
  if !Dir.exists? dir
    print_diagnostic([ "WARNING: no #{dir}/ dir" ])
  else
    #TODO:
  end
end

def check_outputs
  banner __method__.to_s
  if !Dir.exists? outputs_dir
    print_diagnostic([ "WARNING: no #{outputs}/ dir" ])
    return
  end
  check_outputs_colour('red')
  check_outputs_colour('amber')
  check_outputs_colour('green')
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_traffic_lights_colour(rag)
  dir = "#{traffic_lights_dir}/#{rag}"
  if !Dir.exists? dir
    print_diagnostic([ "WARNING: no #{dir}/ dir" ])
  else
    # TODO:
  end
end

def check_traffic_lights
  banner __method__.to_s
  if !Dir.exists? traffic_lights_dir
    print_diagnostic([ "WARNING: no #{traffic_lights}/ dir" ])
    return
  end
  check_traffic_lights_colour('amber')
  check_traffic_lights_colour('green')
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def push_the_image_to_dockerhub
  banner __method__.to_s
  command = [
    'docker login',
    "--username #{docker_username}",
    "--password #{docker_password}"
  ].join(' ')

  # careful not to show password if command fails
  `#{command}`
  status = $?.exitstatus
  unless status == success
    secure = 'secure'
    redacted = [
      'docker login',
      "--username [#{secure}]",
      "--password [#{secure}]"
    ].join(' ')
    print_diagnostic([
      "FAILED:command:#{redacted}",
      "exit_status == #{status}"
    ])
    exit fail
  end

  assert_system "docker push #{image_name}"
  assert_system 'docker logout'
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def trigger_dependent_git_repos
  banner __method__.to_s
  # TODO:
  # NB: I can stick with the javascript based notification
  # I'm using although I should upgrade to using a POST which
  # the travis API v3 now allows. See
  # https://docs.travis-ci.com/user/triggering-builds/
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

verify_dependency_settings
build_the_image
if test_framework_repo?
  check_images_red_amber_green_lambda_file
  check_start_point
  check_outputs
  check_traffic_lights
end

push_the_image_to_dockerhub
trigger_dependent_git_repos

