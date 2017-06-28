#!/usr/bin/env ruby

require_relative 'builder'
require_relative 'docker_login'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# TODO: keep record of all images (in chain) successfully built.
# TODO: push all images to dockerhub at end (ensuring consistent set)

docker_login if running_on_travis?

builder = Builder.new(ENV['SRC_DIR'])
builder.check_my_dependency
builder.check_required_files_exist
builder.build_the_image
if builder.test_framework_repo?
  builder.check_images_red_amber_green_lambda_file
  builder.check_start_point_can_be_created
  builder.check_start_point_src_is_red_using_runner_stateless
  builder.check_start_point_src_is_red_using_runner_statefull
  builder.check_saved_traffic_lights_filesets
  builder.push_the_image_to_dockerhub if running_on_travis?
end
