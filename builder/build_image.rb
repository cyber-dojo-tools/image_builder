#!/usr/bin/env ruby

require_relative 'assert'
require_relative 'check_my_dependency'
require_relative 'check_required_files_exist'
require_relative 'dir_names'
require_relative 'docker_login'
require_relative 'http_service'
require_relative 'logger'
require_relative 'runner_service_statefull'
require_relative 'runner_service_stateless'
require 'json'

def success; 0; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def build_the_image
  banner __method__.to_s
  assert_system "cd #{docker_dir} && docker build --tag #{image_name} ."
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def call_rag_lambda(stdout, stderr, status)
  rag_filename = '/usr/local/bin/red_amber_green.rb'
  cat_rag_filename = "docker run --rm -it #{image_name} cat #{rag_filename}"
  src = assert_backtick cat_rag_filename
  fn = eval(src)
  fn.call(stdout, stderr, status)
end

def check_images_red_amber_green_lambda_file
  # TODO: improve diagnostics
  banner __method__.to_s
  colour = call_rag_lambda(stdout='ssd', stderr='sdsd', status=42)
  unless colour == :amber
    failed [
      "image #{image_name}'s #{rag_filename} sanity check did not produce :amber",
      "colour == #{colour}",
      "stdout == #{stdout}",
      "stderr == #{stderr}",
      "status == #{status}"
    ]
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_start_point_can_be_created
  # TODO: Try the curl several times before failing.
  banner __method__.to_s
  script = 'cyber-dojo'
  url = "https://raw.githubusercontent.com/cyber-dojo/commander/master/#{script}"
  assert_system "curl -O #{url}"
  assert_system "chmod +x #{script}"
  name = 'checking'
  assert_system "./#{script} start-point create #{name} --git=#{repo_url}"
  # TODO: ensure always removed
  assert_system "./#{script} start-point rm #{name}"
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# TODO:
# If /6 * 9/ can be found in the start-point then
#   check that /6 * 7/ is green
#   check that /6 * 9sdsd/ is amber
# If traffic_lights/ sub-dirs exist, test them too
#   ... assume they contain complete filesets?
# If /6 * 9/ can't be found and no traffic_lights/ sub-dirs exist
# then treat that as an error?

def check_start_point_src_is_red
  # Stateless runner
  banner __method__.to_s
  # start-point has already been verified
  manifest = JSON.parse(IO.read(start_point_dir + '/manifest.json'))
  visible_files = {}
  manifest['visible_filenames'].each do |filename|
    visible_files[filename] = IO.read(start_point_dir + '/' + filename)
  end
  image_name = manifest['image_name']
  kata_id = '6F4F4E4759'
  avatar_name = 'salmon'
  runner = RunnerServiceStateless.new
  sss = runner.run(image_name, kata_id, avatar_name, visible_files, max_seconds=10)
  colour = call_rag_lambda(sss['stdout'], sss['stderr'], sss['status'])
  unless colour == :red
    failed [ 'start_point files are not red',
      "colour == #{colour}",
      "stdout == #{stdout}",
      "stderr == #{stderr}",
      "status == #{status}"
    ]
  end
  banner_end
end


def check_start_point_src_is_red_runner_statefull
  # TODO: avatar_old, kata_old  to clean-up
  banner __method__.to_s
  # start-point has already been verified
  manifest = JSON.parse(IO.read(start_point_dir + '/manifest.json'))
  visible_files = {}
  manifest['visible_filenames'].each do |filename|
    visible_files[filename] = IO.read(start_point_dir + '/' + filename)
  end
  image_name = manifest['image_name']
  kata_id = '6F4F4E4759'
  avatar_name = 'salmon'
  runner = RunnerServiceStatefull.new
  runner.kata_new(image_name, kata_id)
  runner.avatar_new(image_name, kata_id, avatar_name, visible_files)
  sss = runner.run(image_name, kata_id, avatar_name, deleted_filenames=[], changed_files={}, max_seconds=10)
  colour = call_rag_lambda(sss['stdout'], sss['stderr'], sss['status'])
  unless colour == :red
    failed [ 'start_point files are not red',
      "colour == #{colour}",
      "stdout == #{stdout}",
      "stderr == #{stderr}",
      "status == #{status}"
    ]
  end
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
  my_dependents.each do |dependent|
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

check_required_files_exist
#docker_login
check_my_dependency
build_the_image

if test_framework_repo?
  check_images_red_amber_green_lambda_file
  #check_start_point_can_be_created
  check_start_point_src_is_red
  #check_saved_traffic_lights_filesets
end

#push_the_image_to_dockerhub
trigger_dependent_git_repos

