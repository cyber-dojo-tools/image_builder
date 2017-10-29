#!/usr/bin/env ruby

require_relative 'image_builder'
require_relative 'travis'

class InnerMain

  def run
    builder = ImageBuilder.new
    builder.build_image
    builder.create_start_point
    builder.test_red_amber_green

    if on_travis_cyber_dojo?
      travis = Travis.new
      travis.validate_image_data_triple
      travis.push_image_to_dockerhub
      travis.trigger_dependents
    end
  end

  private

  def on_travis_cyber_dojo?
    # return false if we are running our own tests
    repo_slug = ENV['TRAVIS_REPO_SLUG']
    ENV['TRAVIS'] == 'true' &&
      repo_slug != 'cyber-dojo-languages/image_builder' &&
      (repo_slug.start_with?('cyber-dojo-languages/') ||
       repo_slug.start_with?('cyber-dojo/'))

  end

end

InnerMain.new.run
