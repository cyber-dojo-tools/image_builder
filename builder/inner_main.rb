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

source = Source.new(ENV['SRC_DIR'])

builder = ImageBuilder.new(source)
if source.docker_dir?
  builder.build_image
end
if source.start_point_dir?
  builder.create_start_point
end
if source.docker_dir? && source.start_point_dir?
  # TODO: not right. Someone could be creating
  # a custom start_point/ and also using a custom docker/
  # In this case, take the image_name from start_point/manifest.json
  builder.test_red_amber_green
end

if on_travis_cyber_dojo? && source.docker_dir?
  travis = Travis.new(source)
  travis.validate_image_data_triple
  travis.push_image_to_dockerhub
  travis.trigger_dependents
end
