#!/usr/bin/env ruby

require_relative 'image_builder'
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

def docker_dir?
  Dir.exist? docker_dir
end

def docker_dir
  src_dir + '/docker'
end

def start_point_dir?
  Dir.exist? start_point_dir
end

def start_point_dir
  src_dir + '/start_point'
end

def src_dir
  ENV['SRC_DIR']
end

# - - - - - - - - - - - - - - - - - - - - - - -

builder = ImageBuilder.new
if docker_dir?
  builder.build_image
end
if start_point_dir?
  builder.create_start_point
end
if docker_dir? && start_point_dir?
  # TODO: not right. Someone could be creating
  # a custom start_point/ and also using a custom docker/
  # In this case, take the image_name from start_point/manifest.json
  builder.test_red_amber_green
end

if on_travis_cyber_dojo? && docker_dir?
  travis = Travis.new
  travis.validate_image_data_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
