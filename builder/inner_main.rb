#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'dir_get_args'
require_relative 'dockerhub'

def running_on_travis?
  ENV['TRAVIS'] == 'true'
end

def push?
  running_on_travis?
end

if push?
  Dockerhub.login
end

src_dir = ENV['SRC_DIR']
args = dir_get_args(src_dir)
builder = ImageBuilder.new(src_dir, args)
image_name = builder.build_and_test_image

if push?
  Dockerhub.push(image_name)
end

puts

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# TODO:
# Running Travis
# Send POST to trigger immediate dependents.
# Probably will involve installing npm and then
# curling the trigger.js file used in cyber-dojo repos.
#
#
# Running locally
# graph-chain-build all dependents?

