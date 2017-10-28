#!/usr/bin/env ruby

require_relative 'assert_system'
require_relative 'banner'
require_relative 'dir_get_args'
require_relative 'dockerhub'
require_relative 'image_builder'
require_relative 'json_parse'
require_relative 'print_to'
require_relative 'travis'

class InnerMain

  def initialize
    @src_dir = ENV['SRC_DIR']
    @args = dir_get_args(@src_dir)
  end

  def run
    t1 = Time.now

    on_travis.validate_image_data_triple
    if running_on_travis?
      dockerhub.login
    end

    builder = ImageBuilder.new(@src_dir, @args)
    builder.build_and_test_image_start_point

    if running_on_travis?
      dockerhub.push_image(image_name)
      dockerhub.logout
      trigger_dependent_repos
    end

    t2 = Time.now
    print_date_time_duration(t1, t2)
  end

  private

  def on_travis
    @travis ||= Travis.new
  end

  def dockerhub
    @dockerhub ||= DockerHub.new
  end

  include AssertSystem
  include Banner
  include DirGetArgs
  include JsonParse
  include PrintTo

  def print_date_time_duration(t1, t2)
    banner {
      assert_system 'date'
      hms = Time.at(t2 - t1).utc.strftime("%H:%M:%S")
      print_to STDOUT, "took #{hms}"
    }
  end

  # - - - - - - - - - - - - - - - - -

  def trigger_dependent_repos
    banner {
      repos = dependent_repos
      print_to STDOUT, "dependent repos: #{repos.size}"
      travis_trigger(repos)
    }
  end

  def travis_trigger(repos)
    if repos.size == 0
      return
    end
    assert_system "travis login --skip-completion-check --github-token ${GITHUB_TOKEN}"
    token = assert_backtick('travis token --org').strip
    assert_system 'travis logout'
    repos.each do |repo_name|
      puts "  #{cdl}/#{repo_name}"
      output = assert_backtick "./app/trigger.sh #{token} #{cdl} #{repo_name}"
      print_to STDOUT, output
      print_to STDOUT, "\n", '- - - - - - - - -'
    end
  end

  def cdl
    'cyber-dojo-languages'
  end

  def dependent_repos
    triples.keys.select { |key| triples[key]['from'] == image_name }
  end

  def image_name
    @args[:image_name]
  end

  # - - - - - - - - - - - - - - - - -

  def triples
    @triples ||= curled_triples
  end

  def curled_triples
    assert_system "curl --silent -O #{triples_url}"
    json_parse(triples_filename, IO.read("./#{triples_filename}"))
  end

  def triples_url
    "https://raw.githubusercontent.com/cyber-dojo-languages/images_info/master/#{triples_filename}"
  end

  def triples_filename
    'images_info.json'
  end

  # - - - - - - - - - - - - - - - - -

  def running_on_travis?
    # return false if we are running image_builder's tests
    ENV['TRAVIS'] == 'true' &&
      ENV['TRAVIS_REPO_SLUG'] != 'cyber-dojo-languages/image_builder'
  end

end

InnerMain.new.run
