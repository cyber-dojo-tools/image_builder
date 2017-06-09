#!/usr/bin/env ruby

require_relative 'dependencies'
require 'json'

def success; 0; end
def fail   ; 1; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_username_env_var; 'DOCKER_USERNAME'; end
def docker_password_env_var; 'DOCKER_PASSWORD'; end

def repo_url       ; ENV['REPO_URL'       ]; end
def docker_username; ENV[docker_username_env_var]; end
def docker_password; ENV[docker_password_env_var]; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def           root_dir; '/language'; end

def         docker_dir; root_dir + '/docker'     ; end
def    start_point_dir; root_dir + '/start_point'; end
def        outputs_dir; root_dir + '/outputs'; end
def traffic_lights_dir; root_dir + '/traffic_lights'; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def print(lines, stream); lines.each { |line| stream.puts line }; end
def print_diagnostic(lines); print(lines, STDERR); end
def print_warning(lines); print_diagnostic(['WARNING'] + lines); end
def print_failed(lines); print_diagnostic(['FAILED'] + lines); end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def banner_line; '=' * 42; end
def banner(title); print([ '', banner_line, title, ], STDOUT); end
def banner_end; print([ 'OK', banner_line ], STDOUT); end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def assert_system(command)
  system command
  status = $?.exitstatus
  unless status == success
    print_failed [ command, "exit_status == #{status}" ]
    exit fail
  end
end

def assert_backtick(command)
  output = `#{command}`
  status = $?.exitstatus
  unless status == success
    print_failed [ command, "exit_status == #{status}" ]
    exit fail
  end
  output
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_image_src?
  File.exists?("#{docker_dir}/Dockerfile")
end

def language_repo_markerfile
  # A language repo always has a /docker/image_name.json file
  # and never has a /start_point/ dir.
  "#{docker_dir}/image_name.json"
end

def test_framework_repo_markerfile
  # If a test-framework repo is re-using an existing docker-image then
  #   /docker/ dir won't exist.
  # If a test-framework has its own docker-image then
  #   /docker/Dockerfile will exist but
  #   /docker/image_name.json will not.
  # This is simply to avoid duplication because the image_name
  # is also specified in the start-point's manifest file.
  # And a test-framework always has a /start_point/ dir.
  "#{start_point_dir}/manifest.json"
end

def language_repo?
  File.exists? language_repo_markerfile
end

def test_framework_repo?
  File.exists? test_framework_repo_markerfile
end

def check_required_directory_structure
  banner __method__.to_s
  either_or = [
    "#{language_repo_markerfile} must exist",
    'or',
    "#{test_framework_repo_markerfile} must exist"
  ]
  if !language_repo? && !test_framework_repo?
    print_failed either_or + [ 'neither do.' ]
    exit fail
  end
  if language_repo? && test_framework_repo?
    print_failed either_or + [ 'but not both.' ]
    exit fail
  end

=begin
  # ? do red/amber/green test dynamically using s/6 * 9/6 * 7/
  if test_framework_repo?
    required_dirs = [
      "#{outputs_dir}/red",
      "#{outputs_dir}/amber",
      "#{outputs_dir}/green",
      "#{traffic_lights_dir}/amber",
      "#{traffic_lights_dir}/green",
    ]
    missing_dirs = required_dirs.select { |dir| !Dir.exists? dir }
    missing_dirs.each do |dir|
      print_failed [ "no #{dir}/ dir" ]
    end
    unless missing_dirs == []
      exit fail
    end
  end
=end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_docker_push_env_vars
  banner __method__.to_s
  if docker_image_src?
    if docker_username == ''
      print_failed [ "#{docker_username_env_var} env-var not set" ]
      exit fail
    end
    if docker_password == ''
      print_filed [ "#{docker_password_env_var} env-var not set" ]
      exit fail
    end
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def from
  dockerfile = IO.read("#{docker_dir}/Dockerfile")
  lines = dockerfile.split("\n")
  from_line = lines.find { |line| line.start_with? 'FROM' }
  from_line.split[1].strip
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def json_image_name(filename)
  manifest = IO.read(filename)
  # TODO: better diagnostics on failure
  json = JSON.parse(manifest)
  json['image_name']
end

def image_name
  if language_repo?
    return json_image_name(language_repo_markerfile)
  end
  if test_framework_repo?
    return json_image_name(test_framework_repo_markerfile)
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_my_dependencies
  banner __method__.to_s
  found = dependencies.include?([ repo_url, from, image_name ])
  unless found
    print_failed [
      'cannot find dependency entry for',
      "    repo_url:#{repo_url}",
      "        from:#{from}",
      "  image_name:#{image_name}"
    ]
    exit fail
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def build_the_image
  if !Dir.exists?(docker_dir)
    return
  end
  banner __method__.to_s
  assert_system "cd #{docker_dir} && docker build --tag #{image_name} ."
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_images_red_amber_green_lambda_file
  # TODO: improve diagnostics
  banner __method__.to_s
  rag_filename = '/usr/local/bin/red_amber_green.rb'
  cat_rag_filename = "docker run --rm -it #{image_name} cat #{rag_filename}"
  src = assert_backtick cat_rag_filename
  fn = eval(src)
  rag = fn.call(stdout='ssd', stderr='sdsd', status=42)
  unless rag == :amber
    print_failed [ "image #{image_name}'s #{rag_filename} did not produce :amber" ]
    exit fail
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_start_point_can_be_created
  banner __method__.to_s
  script = 'cyber-dojo'
  url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
  assert_system "curl -O #{url}"
  assert_system "chmod +x #{script}"
  name = 'checking'
  assert_system "./#{script} start-point create #{name} --git=#{repo_url}"
  #TODO: ensure always removed
  assert_system "./#{script} start-point rm #{name}"
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_start_point_src_is_red
  banner __method__.to_s

  # use runner_stateless
  # run(image_name, kata_id, avatar_name, visible_files, max_seconds)

  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_outputs_colour(rag)
  dir = "#{outputs_dir}/#{rag}"
  # TODO:
  # rag_filename = '/usr/local/bin/red_amber_green.rb'
  # cat_rag_filename = "docker run --rm -it #{image_name} cat #{rag_filename}"
  # src = assert_backtick cat_rag_filename
  # fn = eval(src)
  # rag = fn.call(stdout='ssd', stderr='sdsd', status=42)
end

def check_outputs
  banner __method__.to_s
  ['red','amber','green'].each { |rag| check_outputs_colour rag }
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_traffic_lights_colour(rag)
  dir = "#{traffic_lights_dir}/#{rag}"
  # TODO: run() and use lambda on output
end

def check_traffic_lights
  banner __method__.to_s
  check_traffic_lights_colour 'amber'
  check_traffic_lights_colour 'green'
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def docker_login_cmd(username, password)
  [ 'docker login',
      "--username #{username}",
      "--password #{password}"
  ].join(' ')
end

def docker_login_ready_to_push_image
  banner __method__.to_s
  # careful not to show password if command fails
  `#{docker_login_cmd(docker_username, docker_password)}`
  status = $?.exitstatus
  unless status == success
    print_failed [
      "#{docker_login_cmd('[secure]','[secure]')}",
      "exit_status == #{status}"
    ]
    exit fail
  end
  banner_end
end

def push_the_image_to_dockerhub
  banner __method__.to_s
  print([ "pushing #{image_name}" ], STDOUT)
  assert_system "docker push #{image_name}"
  assert_system 'docker logout'
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def trigger_dependent_git_repos
  banner __method__.to_s
  dependents = dependencies.select do |entry|
    entry[1] == image_name
  end
  dependents.each do |dependent|
    puts "notify:#{dependent[2]}"
    # TODO:
    # NB: I can stick with the javascript based notification
    # I'm using although I should upgrade to using a POST which
    # the travis API v3 now allows. See
    # https://docs.travis-ci.com/user/triggering-builds/
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

check_required_directory_structure

if docker_image_src?
  check_docker_push_env_vars
  check_my_dependencies
  docker_login_ready_to_push_image
  build_the_image
end
if test_framework_repo?
  check_images_red_amber_green_lambda_file
  check_start_point_can_be_created
  check_start_point_src_is_red
  check_outputs
  check_traffic_lights
end
if docker_image_src?
  push_the_image_to_dockerhub
  #TODO: need to check for GITHUB_TOKEN env-var
  trigger_dependent_git_repos
end

