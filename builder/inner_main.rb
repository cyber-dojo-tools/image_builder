#!/usr/bin/env ruby

require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'image_builder'

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

if running_on_travis?
  Dockerhub.login
end

src_dir = ENV['SRC_DIR']
args = dir_get_args(src_dir)
builder = ImageBuilder.new(src_dir, args)
image_name = builder.build_and_test_image

if running_on_travis?
  Dockerhub.push(image_name)
  # Send POST to trigger immediate dependents.
  # Probably will involve installing npm and then
  # curling the trigger.js file used in cyber-dojo repos.
end
