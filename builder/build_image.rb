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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# TODO: Don't trigger_dependent_git_repos.
#       Instead have option to control when this run is for a single
#       repo or it for a chain starting with this repo.
#       If for a chain, start by creating a list of all the dependents.
#       Then build these in a chain, one by one.
#       This will considerably speed up Travis cycle-time since
#       Travis won't need to [docker pull] the image created on
#       the [docker push] step for the previous repo.
#       However, it may start to hit the 50min max time for
#       a single (public) Travis run.
#
# TODO: If TRAVIS env-var is defined check if DOCKER_ env-vars
#       are defined. If they are not issue error diagnostic and fail.
#       If TRAVIS env-var is not defined, check if DOCKER_ env-vars
#       are defined. If they are not issue warning diagnostic and continue
#       and do not do [docker login/push] commands.
#
#       If on Travis do a [git clone] of dependent repo
#       to continue the image-chain build.
#       If not on Travis, instead of doing [git clone]
#       assume the repo is in .. dir and simply use that.
#
#       Also, when not on Travis, instead of curling the
#       cyber-dojo script, check if cyber-dojo script is on path
#       and if so, use that. If no cyber-dojo script on path
#       then issue an error.
#
# TODO: add information on how long red/amber/green runs take.
#       issue warning if they take too long?

def success; 0; end
def rag_filename; '/usr/local/bin/red_amber_green.rb'; end
def kata_id; '6F4F4E4759'; end
def avatar_name; 'salmon'; end
def max_seconds; 10; end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def build_the_image
  banner __method__.to_s
  assert_system "cd #{docker_dir} && docker build --tag #{image_name} ."
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def assert_rag(expected_colour, sss, diagnostic)
  actual_colour = call_rag_lambda(sss)
  unless expected_colour == actual_colour
    failed [ diagnostic,
      "expected_colour == #{expected_colour}",
      "  actual_colour == #{actual_colour}",
      "stdout == #{sss['stdout']}",
      "stderr == #{sss['stderr']}",
      "status == #{sss['status']}"
    ]
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def call_rag_lambda(sss)
  # TODO: improve diagnostics if cat/eval/call fails
  cat_rag_filename = "docker run --rm -it #{image_name} cat #{rag_filename}"
  src = assert_backtick cat_rag_filename
  fn = eval(src)
  fn.call(sss['stdout'], sss['stderr'], sss['status'])
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_images_red_amber_green_lambda_file
  banner __method__.to_s
  sss = { 'stdout' => 'sdd', 'stderr' => 'sdsd', 'status' => 42 }
  assert_rag(:amber, sss, "#{rag_filename} sanity check")
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

def start_point_visible_files
  # start-point has already been verified
  manifest = JSON.parse(IO.read(start_point_dir + '/manifest.json'))
  visible_files = {}
  manifest['visible_filenames'].each do |filename|
    visible_files[filename] = IO.read(start_point_dir + '/' + filename)
  end
  visible_files
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_start_point_src_is_red_runner_stateless
  banner __method__.to_s
  runner = RunnerServiceStateless.new
  sss = runner.run(image_name, kata_id, avatar_name, start_point_visible_files, max_seconds)
  assert_rag(:red, sss, "dir == #{start_point_dir}")
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_start_point_src_is_red_runner_statefull
  banner __method__.to_s
  runner = RunnerServiceStatefull.new
  runner.kata_new(image_name, kata_id)
  runner.avatar_new(image_name, kata_id, avatar_name, start_point_visible_files)
  sss = runner.run(image_name, kata_id, avatar_name, deleted_filenames=[], changed_files={}, max_seconds)
  runner.avatar_old(image_name, kata_id, avatar_name)
  runner.kata_old(image_name, kata_id)
  assert_rag(:red, sss, "dir == #{start_point_dir}")
  banner_end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def check_saved_traffic_lights_filesets
  banner __method__.to_s
  # If /6 * 9/ can be found in the start-point then
  #   check that /6 * 7/ is green
  #   check that /6 * 9sdsd/ is amber
  # If traffic_lights/ sub-dirs exist, test them too
  #   ... assume they contain complete filesets?
  # If /6 * 9/ can't be found and no traffic_lights/ sub-dirs exist
  # then treat that as an error?
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
docker_login
check_my_dependency
build_the_image

if test_framework_repo?
  check_images_red_amber_green_lambda_file
  check_start_point_can_be_created
  check_start_point_src_is_red_runner_stateless
  check_start_point_src_is_red_runner_statefull
  check_saved_traffic_lights_filesets
end

push_the_image_to_dockerhub
trigger_dependent_git_repos

