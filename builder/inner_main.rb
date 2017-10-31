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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

src_dir = ENV['SRC_DIR']
start_point = SourceStartPoint.new(src_dir)
docker = SourceDocker.new(src_dir + '/docker')

image_name = nil
if start_point.dir?
  start_point.test_create
  image_name = start_point.image_name
end
if docker.dir?
  image_name = docker.build_image(image_name)
end
if start_point.dir?
  start_point.test_run
end

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

if on_travis_cyber_dojo? && docker.dir?
  triple = {
      'from'           => docker.image_FROM,
      'image_name'     => image_name,
      'test_framework' => start_point.dir?
    }
  travis = Travis.new(triple)
  travis.validate_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
