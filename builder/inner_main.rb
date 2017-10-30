#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'source_docker'
require_relative 'source_start_point'
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

src_dir = ENV['SRC_DIR']
start_point = SourceStartPoint.new(src_dir)
docker = SourceDocker.new(src_dir)

image_name = nil
if start_point.dir?
  start_point.test_create
  image_name = start_point.image_name
end

if docker.dir?
  docker.build_image(image_name)
end

if docker.dir? && start_point.dir?
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
  #
  # But at the same time, if being run on a cyber-dojo-langauges repo
  # should check it _has_ 6*9 content

  start_point.test_red_amber_green
end

if on_travis_cyber_dojo? && docker.dir?
  triple = {
      'from' => docker.from,
      'image_name' => image_name,
      'test_framework' => start_point.dir?
    }
  travis = Travis.new(triple)
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
