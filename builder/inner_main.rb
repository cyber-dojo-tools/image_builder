#!/usr/bin/env ruby

require_relative 'assert_system'
require_relative 'banner'
require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'image_builder'
require_relative 'print_to'
require_relative 'travis'

class InnerMain

  def initialize
    @src_dir = ENV['SRC_DIR']
    @args = dir_get_args(@src_dir)
  end

  def run
    t1 = Time.now

    builder = ImageBuilder.new(@src_dir, @args)
    builder.build_and_test_image_start_point

    if running_on_travis?
      travis.validate_image_data_triple
      dockerhub.push(image_name)
      travis.trigger_dependent_repos
    end

    t2 = Time.now
    print_date_time_duration(t1, t2)
  end

  private

  include AssertSystem
  include Banner
  include DirGetArgs
  include PrintTo

  def travis
    @travis ||= Travis.new
  end

  def dockerhub
    @dockerhub ||= DockerHub.new
  end

  def image_name
    @args[:image_name]
  end

  def print_date_time_duration(t1, t2)
    banner {
      assert_system 'date'
      hms = Time.at(t2 - t1).utc.strftime("%H:%M:%S")
      print_to STDOUT, "took #{hms}"
    }
  end

  # - - - - - - - - - - - - - - - - -

  def running_on_travis?
    # return false if we are running image_builder's tests
    ENV['TRAVIS'] == 'true' &&
      ENV['TRAVIS_REPO_SLUG'] != 'cyber-dojo-languages/image_builder'
  end

end

InnerMain.new.run
