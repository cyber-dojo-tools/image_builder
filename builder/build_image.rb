#!/usr/bin/env ruby

require_relative 'builder'
require_relative 'dockerhub'
require_relative 'dependencies'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

src_dir = ENV['SRC_DIR']
args = dependencies[src_dir]

Dockerhub.login if running_on_travis?

builder = Builder.new(src_dir, args)
builder.check_required_files_exist
builder.build_the_image
if builder.test_framework_repo?
  builder.check_images_red_amber_green_lambda_file
  builder.check_start_point_can_be_created
  builder.check_start_point_src_is_red_using_runner_stateless
  builder.check_start_point_src_is_red_using_runner_statefull
  builder.check_amber_green_filesets
end
Dockerhub.push(builder.image_name) if running_on_travis?
