#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'docker_dir'
require_relative 'start_point_dir'
require_relative 'start_point'
require_relative 'travis'

def on_travis_cyber_dojo?
  # return false if we are running our own tests
  repo_slug = ENV['TRAVIS_REPO_SLUG']
  ENV['TRAVIS'] == 'true' &&
    repo_slug != 'cyber-dojo-languages/image_builder' &&
    (repo_slug.start_with?('cyber-dojo-languages/') ||
     repo_slug.start_with?('cyber-dojo/'))
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

start_point = StartPoint.new(ENV['SRC_DIR'])
start_point.assert_create

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

docker_dirs,start_point_dirs = start_point.dirs

docker_dir = docker_dirs[0]
start_point_dir = start_point_dirs[0]

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

image_name = nil
if start_point_dir
  image_name = start_point_dir.image_name
end
if docker_dir
  image_name = docker_dir.build_image(image_name)
end
if start_point_dir
  start_point_dir.test_run
end

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

if on_travis_cyber_dojo? && docker_dir
  triple = {
      'from'           => docker_dir.image_FROM,
      'image_name'     => image_name,
      'test_framework' => !start_point_dir.nil?
    }
  travis = Travis.new(triple)
  travis.validate_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
