#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'docker_dir'
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

src_dir = ENV['SRC_DIR']
# does src_dir have a start_point_type.json file?
# if so, this is the dir to do test_create() on.
# If this works, I can find all the manifest.json files
# underneath this dir and process them each. Names...
# [start_point_dir] - contains a start_point_type.json file, contains 1 or more
# [start_point] - a dir holding a manifest.json file.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If there is only one docker_dir and one start_point_dir
# then the start-point dir's manifest determines the image_name
# and the docker_dir does not need an image_name.json file.
# Otherwise it does.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Also need to check that a named docker-image is
# used in at least one manifest.json file.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


start_point_dir = SourceStartPoint.new(src_dir)
docker_dir = DockerDir.new(src_dir + '/docker')

image_name = nil
if start_point_dir.exist?
  start_point_dir.test_create
  image_name = start_point_dir.image_name
end
if docker_dir.exist?
  image_name = docker_dir.build_image(image_name)
end
if start_point_dir.exist?
  start_point_dir.test_run
end

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

if on_travis_cyber_dojo? && docker_dir.exist?
  triple = {
      'from'           => docker_dir.image_FROM,
      'image_name'     => image_name,
      'test_framework' => start_point_dir.exist?
    }
  travis = Travis.new(triple)
  travis.validate_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
