#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'source'
require_relative 'travis'

def on_travis_cyber_dojo?
  # return false if we are running our own tests
  repo_slug = ENV['TRAVIS_REPO_SLUG']
  ENV['TRAVIS'] == 'true' &&
    repo_slug != 'cyber-dojo-languages/image_builder' &&
    (repo_slug.start_with?('cyber-dojo-languages/') ||
     repo_slug.start_with?('cyber-dojo/'))
end

# - - - - - - - - - - - - - - - - - - - - - - -

source = Source.new(ENV['SRC_DIR'])

builder = ImageBuilder.new(source)
if source.docker_dir?
  builder.build_image
end
if source.start_point.dir?
  source.start_point.test_create
end
if source.docker_dir? && source.start_point.dir?
  #
  # TODO: not right.
  # Suppose someone wants a local 9*6 start_point?
  # So __look-for__ a 9*6 file (or options.json)
  #
  # if source.has_6_times_9?
  #   builder.test_6_times_9_red_amber_green
  # else
  #   builder.test_run
  # end
  #
  # This suggests the reading of files (eg in start_point)
  # should come from source.methods

  source.start_point.test_red_amber_green
end

if on_travis_cyber_dojo? && source.docker_dir?
  travis = Travis.new(source)
  travis.validate_image_data_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
