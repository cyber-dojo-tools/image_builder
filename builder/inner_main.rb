#!/usr/bin/env ruby

require_relative 'dir_get_args'
require_relative 'image_builder'
require_relative 'travis'

class InnerMain

  def initialize
    @src_dir = ENV['SRC_DIR']
    @args = dir_get_args(@src_dir)
  end

  def run
    builder = ImageBuilder.new(@src_dir, @args)
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

  include DirGetArgs

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
